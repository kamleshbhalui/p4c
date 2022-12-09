/*
Copyright 2018-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "p4RuntimeArchStandard.h"

#include <set>
#include <unordered_map>

#include <boost/optional.hpp>

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "lib/log.h"
#include "p4RuntimeArchHandler.h"
#include "typeSpecConverter.h"

namespace P4 {

/** \addtogroup control_plane
 *  @{
 */
namespace ControlPlaneAPI {

namespace Standard {

/// Implements @ref P4RuntimeArchHandlerIface for the v1model architecture. The
/// overridden methods will be called by the @P4RuntimeSerializer to collect and
/// serialize v1model-specific symbols which are exposed to the control-plane.
class P4RuntimeArchHandlerV1Model final : public P4RuntimeArchHandlerCommon<Arch::V1MODEL> {
 public:
    P4RuntimeArchHandlerV1Model(ReferenceMap* refMap, TypeMap* typeMap,
                                const IR::ToplevelBlock* evaluatedProgram)
        : P4RuntimeArchHandlerCommon<Arch::V1MODEL>(refMap, typeMap, evaluatedProgram) {}

    void collectExternFunction(P4RuntimeSymbolTableIface* symbols,
                               const P4::ExternFunction* externFunction) override {
        auto digest = getDigestCall(externFunction, refMap, typeMap, nullptr);
        if (digest) symbols->add(SymbolType::DIGEST(), digest->name);
    }

    void addTableProperties(const P4RuntimeSymbolTableIface& symbols, p4configv1::P4Info* p4info,
                            p4configv1::Table* table, const IR::TableBlock* tableBlock) override {
        P4RuntimeArchHandlerCommon<Arch::V1MODEL>::addTableProperties(symbols, p4info, table,
                                                                      tableBlock);
        auto tableDeclaration = tableBlock->container;

        bool supportsTimeout = getSupportsTimeout(tableDeclaration);
        if (supportsTimeout) {
            table->set_idle_timeout_behavior(p4configv1::Table::NOTIFY_CONTROL);
        } else {
            table->set_idle_timeout_behavior(p4configv1::Table::NO_TIMEOUT);
        }
    }

    void addExternFunction(const P4RuntimeSymbolTableIface& symbols, p4configv1::P4Info* p4info,
                           const P4::ExternFunction* externFunction) override {
        auto p4RtTypeInfo = p4info->mutable_type_info();
        auto digest = getDigestCall(externFunction, refMap, typeMap, p4RtTypeInfo);
        if (digest) addDigest(symbols, p4info, *digest);
    }

    /// @return serialization information for the digest() call represented by
    /// @call, or boost::none if @call is not a digest() call or is invalid.
    static boost::optional<Digest> getDigestCall(const P4::ExternFunction* function,
                                                 ReferenceMap* refMap, P4::TypeMap* typeMap,
                                                 p4configv1::P4TypeInfo* p4RtTypeInfo) {
        if (function->method->name != P4V1::V1Model::instance.digest_receiver.name)
            return boost::none;

        auto call = function->expr;
        BUG_CHECK(call->typeArguments->size() == 1, "%1%: Expected one type argument", call);
        BUG_CHECK(call->arguments->size() == 2, "%1%: Expected 2 arguments", call);

        // An invocation of digest() looks like this:
        //   digest<T>(receiver, { fields });
        // The name that shows up in the control plane API is the type name T. If T
        // doesn't have a name (e.g. tuple), we auto-generate one; ideally we would
        // be able to annotate the digest method call with a @name annotation in the
        // P4 but annotations are not supported on expressions.
        cstring controlPlaneName;
        auto* typeArg = call->typeArguments->at(0);
        if (typeArg->is<IR::Type_StructLike>()) {
            auto structType = typeArg->to<IR::Type_StructLike>();
            controlPlaneName = structType->controlPlaneName();
        } else if (auto* typeName = typeArg->to<IR::Type_Name>()) {
            auto* referencedType = refMap->getDeclaration(typeName->path, true);
            CHECK_NULL(referencedType);
            controlPlaneName = referencedType->controlPlaneName();
        } else {
            static std::unordered_map<const IR::MethodCallExpression*, cstring> autoNames;
            auto it = autoNames.find(call);
            if (it == autoNames.end()) {
                controlPlaneName = "digest_" + cstring::to_cstring(autoNames.size());
                ::warning(ErrorType::WARN_MISMATCH,
                          "Cannot find a good name for %1% method call, using "
                          "auto-generated name '%2%'",
                          call, controlPlaneName);
                autoNames.emplace(call, controlPlaneName);
            } else {
                controlPlaneName = it->second;
            }
        }

        // Convert the generic type for the digest method call to a P4DataTypeSpec
        auto* typeSpec = TypeSpecConverter::convert(refMap, typeMap, typeArg, p4RtTypeInfo);
        BUG_CHECK(typeSpec != nullptr,
                  "P4 type %1% could not "
                  "be converted to P4Info P4DataTypeSpec");
        return Digest{controlPlaneName, typeSpec, nullptr};
    }

    /// @return true if @table's 'support_timeout' property exists and is true. This
    /// indicates that @table supports entry ageing.
    static bool getSupportsTimeout(const IR::P4Table* table) {
        auto timeout = table->properties->getProperty(
            P4V1::V1Model::instance.tableAttributes.supportTimeout.name);
        if (timeout == nullptr) return false;
        if (!timeout->value->is<IR::ExpressionValue>()) {
            ::error(ErrorType::ERR_UNEXPECTED,
                    "Unexpected value %1% for supports_timeout on table %2%", timeout, table);
            return false;
        }

        auto expr = timeout->value->to<IR::ExpressionValue>()->expression;
        if (!expr->is<IR::BoolLiteral>()) {
            ::error(ErrorType::ERR_UNEXPECTED,
                    "Unexpected non-boolean value %1% for supports_timeout "
                    "property on table %2%",
                    timeout, table);
            return false;
        }

        return expr->to<IR::BoolLiteral>()->value;
    }
};

P4RuntimeArchHandlerIface* V1ModelArchHandlerBuilder::operator()(
    ReferenceMap* refMap, TypeMap* typeMap, const IR::ToplevelBlock* evaluatedProgram) const {
    return new P4RuntimeArchHandlerV1Model(refMap, typeMap, evaluatedProgram);
}

/// Implements  a common @ref P4RuntimeArchHandlerIface for the PSA and PNA architecture. The
/// overridden methods will be called by the @P4RuntimeSerializer to collect and
/// serialize PSA and PNA specific symbols which are exposed to the control-plane.
template <Arch arch>
class P4RuntimeArchHandlerPSAPNA : public P4RuntimeArchHandlerCommon<arch> {
 public:
    P4RuntimeArchHandlerPSAPNA(ReferenceMap* refMap, TypeMap* typeMap,
                               const IR::ToplevelBlock* evaluatedProgram)
        : P4RuntimeArchHandlerCommon<arch>(refMap, typeMap, evaluatedProgram) {}

    void collectExternInstance(P4RuntimeSymbolTableIface* symbols,
                               const IR::ExternBlock* externBlock) override {
        P4RuntimeArchHandlerCommon<arch>::collectExternInstance(symbols, externBlock);

        auto decl = externBlock->node->to<IR::IDeclaration>();
        if (decl == nullptr) return;
        if (externBlock->type->name == "Digest") {
            symbols->add(SymbolType::DIGEST(), decl);
        } else if (externBlock->type->name == MatchValueLookupTableExtern::typeName()) {
            symbols->add(SymbolType::MATCH_VALUE_LOOKUP_TABLE(), decl->controlPlaneName());
        }
    }

    void addTableProperties(const P4RuntimeSymbolTableIface& symbols, p4configv1::P4Info* p4info,
                            p4configv1::Table* table, const IR::TableBlock* tableBlock) override {
        P4RuntimeArchHandlerCommon<arch>::addTableProperties(symbols, p4info, table, tableBlock);

        auto tableDeclaration = tableBlock->container;
        bool supportsTimeout = getSupportsTimeout(tableDeclaration);
        if (supportsTimeout) {
            table->set_idle_timeout_behavior(p4configv1::Table::NOTIFY_CONTROL);
        } else {
            table->set_idle_timeout_behavior(p4configv1::Table::NO_TIMEOUT);
        }
    }

    static p4configv1::Extern* getP4InfoExtern(P4RuntimeSymbolType typeId, cstring typeName,
                                               p4configv1::P4Info* p4info) {
        for (auto& externType : *p4info->mutable_externs()) {
            if (externType.extern_type_id() == static_cast<p4rt_id_t>(typeId)) return &externType;
        }
        auto* externType = p4info->add_externs();
        externType->set_extern_type_id(static_cast<p4rt_id_t>(typeId));
        externType->set_extern_type_name(typeName);
        return externType;
    }

    static cstring prefix(cstring p, cstring str) {
        return p.isNullOrEmpty() ? str : p + "." + str;
    }
    void addP4InfoExternInstance(const P4RuntimeSymbolTableIface& symbols,
                                 P4RuntimeSymbolType typeId, cstring typeName, cstring name,
                                 const IR::IAnnotated* annotations,
                                 const ::google::protobuf::Message& message,
                                 p4configv1::P4Info* p4info, cstring pipeName) {
        auto* externType = getP4InfoExtern(typeId, typeName, p4info);
        auto* externInstance = externType->add_instances();
        auto* pre = externInstance->mutable_preamble();
        pre->set_id(symbols.getId(typeId, name));
        pre->set_name(prefix(pipeName, name));
        pre->set_alias(symbols.getAlias(name));
        Helpers::addAnnotations(pre, annotations);
        Helpers::addDocumentation(pre, annotations);
        externInstance->mutable_info()->PackFrom(message);
    }

    void addMatchValueLookupTable(const P4RuntimeSymbolTableIface& symbols,
                                  p4configv1::P4Info* p4Info, const MatchValueLookupTable& mvltbl,
                                  cstring pipeName = "") {
        p4configv1::MatchValueLookupTable p4info_mvlut;
        // set fixed match filed
        p4configv1::MatchField* match = p4info_mvlut.add_match_fields();
        match->set_id(1);
        match->set_name(mvltbl.key_name);
        match->set_bitwidth(mvltbl.key_bitwidth);
        match->set_match_type(p4configv1::MatchField_MatchType_EXACT);

        // set values
        for (auto p : mvltbl.params) {
            auto param = p4info_mvlut.add_params();
            param->set_id(p.id);
            param->set_name(p.name.c_str());
            param->set_bitwidth(p.bitwidth);
        }

        // set size field
        p4info_mvlut.set_size(mvltbl.size);

        // add the MVLUT instance into p4info
        addP4InfoExternInstance(symbols, SymbolType::MATCH_VALUE_LOOKUP_TABLE(),
                                MatchValueLookupTableExtern::directTypeName(), mvltbl.name,
                                mvltbl.annotations, p4info_mvlut, p4Info, pipeName);
    }

    void add_mvlut_param(uint32_t& param_count, std::vector<mvlut_param_t>* params_list,
                         const IR::Type* type, cstring decl_name, cstring prefix) {
        if (type->is<IR::Type_Struct>()) {
            auto stype = type->to<IR::Type_Struct>();
            cstring newprefix = prefix != "" ? prefix + "_" + decl_name : decl_name;
            for (auto field : stype->fields) {
                add_mvlut_param(param_count, params_list, field->type, field->getName().name,
                                newprefix);
            }
        } else {
            cstring param_name = prefix == "" ? decl_name : prefix + "_" + decl_name;
            params_list->emplace_back(
                mvlut_param_t{param_count++, param_name, (uint32_t)type->width_bits()});
        }
    }

    boost::optional<MatchValueLookupTable> getMatchValueLookupTable(
        const IR::ExternBlock* instance) {
        auto decl = instance->node->to<IR::Declaration_Instance>();
        // to be deleted, used to support deprecated ActionSelector constructor.
        BUG_CHECK(decl->type->is<IR::Type_Specialized>(), "%1%: expected Type_Specialized",
                  decl->type);

        auto type = decl->type->to<IR::Type_Specialized>();
        BUG_CHECK(type->arguments->size() == 3, "%1%: expected three type arguments ", decl);
        cstring inst_name = decl->controlPlaneName();
        // get key parameter bitwidth
        uint32_t key_parameter_bitwidth = 0;
        auto key_type = type->arguments->at(0);
        cstring key_name;
        if (auto atype = key_type->to<IR::Type_Bits>()) {
            cstring key_prefix = inst_name + "_key";
            // Remove the control block name prefix if exists
            cstring str_token = key_prefix.findlast('.');
            if (str_token != nullptr) {
                key_prefix = str_token.trim(".\t\n\r");
            }
            key_name = this->refMap->newName(key_prefix);
            key_parameter_bitwidth = (uint32_t)atype->width_bits();
        } else if (key_type->is<IR::Type_Name>()) {
            auto type_decl =
                this->refMap->getDeclaration(key_type->to<IR::Type_Name>()->path, true);
            CHECK_NULL(type_decl);
            const IR::Type* ty = this->typeMap->getType(type_decl->getNode())->getP4Type();
            CHECK_NULL(ty);
            if (ty->is<IR::Type_Struct>()) {
                auto st_type = ty->to<IR::Type_Struct>();
                if (st_type->fields.size() != 1) {
                    ::error(ErrorType::ERR_INVALID,
                            "%1%: struct type for key shall have only "
                            "one field in %2%",
                            key_type, decl);
                    return boost::none;
                }
                auto field_it = st_type->fields.begin();
                key_name = (*field_it)->name;
                // assign the unwrapped struct type as key type for later processing
                key_type = st_type;
                key_parameter_bitwidth = (uint32_t)key_type->width_bits();
            }
        } else {
            ::error(ErrorType::ERR_INVALID,
                    "%1%: Invalid key type in %2%. Expected bit "
                    "type or struct type with one bit type member",
                    key_type, decl);
            return boost::none;
        }

        // get size field value
        auto size_param = instance->getParameterValue("size");
        BUG_CHECK(size_param->is<IR::Constant>(),
                  "Unexpected non constant expression as size argument %1%.", size_param);
        int val = size_param->to<IR::Constant>()->asInt();
        if (val < 0) {
            ::error(ErrorType::ERR_INVALID, "%1%: Invalid value for size argument", size_param);
            return boost::none;
        }
        size_t size_val = (unsigned int)val;

        // create the MVLUT object
        MatchValueLookupTable tbl(inst_name, key_name, key_parameter_bitwidth, {}, size_val,
                                  decl->to<IR::IAnnotated>());

        // record the parameter values for MVLUT
        uint32_t param_count = 1;
        auto arg_type = type->arguments->at(1);
        if (auto* type_name = arg_type->to<IR::Type_Name>()) {
            auto* decl = this->refMap->getDeclaration(type_name->path, true);
            CHECK_NULL(decl);
            const IR::Type* type = this->typeMap->getType(decl->getNode());
            type = type->is<IR::Type_Type>() ? type->to<IR::Type_Type>()->type : type;
            add_mvlut_param(param_count, &tbl.params, type, "", "");
        } else if (auto atype = arg_type->to<IR::Type_Bits>()) {
            add_mvlut_param(param_count, &tbl.params, atype, "", "");
        } else {
            ::error(ErrorType::ERR_INVALID,
                    "%1%: Invalid type for config parameter in %2% "
                    "instance.",
                    arg_type, this->EXACT_MVLUT_NAME);
            return boost::none;
        }

        return tbl;
    }

    void addExternInstance(const P4RuntimeSymbolTableIface& symbols, p4configv1::P4Info* p4info,
                           const IR::ExternBlock* externBlock) override {
        P4RuntimeArchHandlerCommon<arch>::addExternInstance(symbols, p4info, externBlock);
        auto decl = externBlock->node->to<IR::Declaration_Instance>();
        if (decl == nullptr) return;
        auto p4RtTypeInfo = p4info->mutable_type_info();
        if (externBlock->type->name == "Digest") {
            auto digest = getDigest(decl, p4RtTypeInfo);
            if (digest) this->addDigest(symbols, p4info, *digest);
        } else if (externBlock->type->name == MatchValueLookupTableExtern::typeName()) {
            auto mvl_table = getMatchValueLookupTable(externBlock);
            if (mvl_table) addMatchValueLookupTable(symbols, p4info, *mvl_table);
        }
    }

    /// @return serialization information for the Digest extern instacne @decl
    boost::optional<Digest> getDigest(const IR::Declaration_Instance* decl,
                                      p4configv1::P4TypeInfo* p4RtTypeInfo) {
        BUG_CHECK(decl->type->is<IR::Type_Specialized>(), "%1%: expected Type_Specialized",
                  decl->type);
        auto type = decl->type->to<IR::Type_Specialized>();
        BUG_CHECK(type->arguments->size() == 1, "%1%: expected one type argument", decl);
        auto typeArg = type->arguments->at(0);
        auto typeSpec =
            TypeSpecConverter::convert(this->refMap, this->typeMap, typeArg, p4RtTypeInfo);
        BUG_CHECK(typeSpec != nullptr,
                  "P4 type %1% could not be converted to P4Info P4DataTypeSpec");

        return Digest{decl->controlPlaneName(), typeSpec, decl->to<IR::IAnnotated>()};
    }

    /// @return true if @table's 'psa_idle_timeout' property exists and is true. This
    /// indicates that @table supports entry ageing.
    static bool getSupportsTimeout(const IR::P4Table* table) {
        auto timeout = table->properties->getProperty("psa_idle_timeout");

        if (timeout == nullptr) return false;

        if (auto exprValue = timeout->value->to<IR::ExpressionValue>()) {
            if (auto expr = exprValue->expression) {
                if (auto member = expr->to<IR::Member>()) {
                    if (member->member == "NOTIFY_CONTROL") {
                        return true;
                    } else if (member->member == "NO_TIMEOUT") {
                        return false;
                    }
                } else if (expr->is<IR::PathExpression>()) {
                    ::error(ErrorType::ERR_UNEXPECTED,
                            "Unresolved value %1% for psa_idle_timeout "
                            "property on table %2%. Must be a constant and one of "
                            "{ NOTIFY_CONTROL, NO_TIMEOUT }",
                            timeout, table);
                    return false;
                }
            }
        }

        ::error(ErrorType::ERR_UNEXPECTED,
                "Unexpected value %1% for psa_idle_timeout "
                "property on table %2%. Supported values are "
                "{ NOTIFY_CONTROL, NO_TIMEOUT }",
                timeout, table);
        return false;
    }
};

class P4RuntimeArchHandlerPSA final : public P4RuntimeArchHandlerPSAPNA<Arch::PSA> {
 public:
    P4RuntimeArchHandlerPSA(ReferenceMap* refMap, TypeMap* typeMap,
                            const IR::ToplevelBlock* evaluatedProgram)
        : P4RuntimeArchHandlerPSAPNA(refMap, typeMap, evaluatedProgram) {}
};

P4RuntimeArchHandlerIface* PSAArchHandlerBuilder::operator()(
    ReferenceMap* refMap, TypeMap* typeMap, const IR::ToplevelBlock* evaluatedProgram) const {
    return new P4RuntimeArchHandlerPSA(refMap, typeMap, evaluatedProgram);
}

class P4RuntimeArchHandlerPNA final : public P4RuntimeArchHandlerPSAPNA<Arch::PNA> {
 public:
    P4RuntimeArchHandlerPNA(ReferenceMap* refMap, TypeMap* typeMap,
                            const IR::ToplevelBlock* evaluatedProgram)
        : P4RuntimeArchHandlerPSAPNA(refMap, typeMap, evaluatedProgram) {}
};

P4RuntimeArchHandlerIface* PNAArchHandlerBuilder::operator()(
    ReferenceMap* refMap, TypeMap* typeMap, const IR::ToplevelBlock* evaluatedProgram) const {
    return new P4RuntimeArchHandlerPNA(refMap, typeMap, evaluatedProgram);
}

/// Implements @ref P4RuntimeArchHandlerIface for the UBPF architecture.
/// We re-use PSA to handle externs.
/// Rationale: The only configurable extern object in ubpf_model.p4 is Register.
/// The Register is defined exactly the same as for PSA. Therefore, we can re-use PSA.
class P4RuntimeArchHandlerUBPF final : public P4RuntimeArchHandlerCommon<Arch::PSA> {
 public:
    P4RuntimeArchHandlerUBPF(ReferenceMap* refMap, TypeMap* typeMap,
                             const IR::ToplevelBlock* evaluatedProgram)
        : P4RuntimeArchHandlerCommon<Arch::PSA>(refMap, typeMap, evaluatedProgram) {}
};

P4RuntimeArchHandlerIface* UBPFArchHandlerBuilder::operator()(
    ReferenceMap* refMap, TypeMap* typeMap, const IR::ToplevelBlock* evaluatedProgram) const {
    return new P4RuntimeArchHandlerUBPF(refMap, typeMap, evaluatedProgram);
}

}  // namespace Standard

}  // namespace ControlPlaneAPI

/** @} */ /* end group control_plane */
}  // namespace P4
