/* Copyright 2021 Intel Corporation

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
#ifndef DPDK_CONTROL_PLANE_BFRUNTIME_ARCH_HANDLER_H_
#define DPDK_CONTROL_PLANE_BFRUNTIME_ARCH_HANDLER_H_

#include <iostream>
#include <set>
#include <unordered_map>
#include <vector>

#include <boost/optional.hpp>

#include "control-plane/bfruntime.h"
#include "control-plane/p4RuntimeArchHandler.h"
#include "control-plane/p4RuntimeArchStandard.h"
#include "control-plane/p4RuntimeSerializer.h"
#include "control-plane/typeSpecConverter.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/externInstance.h"
#include "frontends/p4/methodInstance.h"
#include "frontends/p4/typeMap.h"
#include "midend/eliminateTypedefs.h"
#include "p4/config/dpdk/p4info.pb.h"

using P4::ReferenceMap;
using P4::TypeMap;
using P4::ControlPlaneAPI::Helpers::getExternInstanceFromProperty;
using P4::ControlPlaneAPI::Helpers::isExternPropertyConstructedInPlace;

namespace p4configv1 = ::p4::config::v1;

namespace P4 {

/** \addtogroup control_plane
 *  @{
 */
namespace ControlPlaneAPI {

/// Declarations specific to standard architectures (v1model & PSA).
namespace Standard {

cstring prefix(cstring p, cstring str) { return p.isNullOrEmpty() ? str : p + "." + str; }

/// Extends P4RuntimeSymbolType for the DPDK extern types.
class SymbolTypeDPDK final : public SymbolType {
 public:
    SymbolTypeDPDK() = delete;

    static P4RuntimeSymbolType ACTION_SELECTOR() {
        return P4RuntimeSymbolType::make(dpdk::P4Ids::ACTION_SELECTOR);
    }
};

/// The information about an action profile which is necessary to generate its
/// serialized representation.
struct ActionSelector {
    const cstring name;  // The fully qualified external name of this action selector.
    const int64_t size;  // TODO(hanw): size does not make sense with new ActionSelector P4 extern
    const int64_t maxGroupSize;
    const int64_t numGroups;
    const IR::IAnnotated* annotations;  // If non-null, any annotations applied to this action
                                        // profile declaration.

    static constexpr int64_t defaultMaxGroupSize = 120;

    p4rt_id_t getId(const P4RuntimeSymbolTableIface& symbols) const {
        return symbols.getId(SymbolTypeDPDK::ACTION_SELECTOR(), name + "_sel");
    }
};

template <Arch arch>
class BFRuntimeArchHandler : public P4RuntimeArchHandlerCommon<arch> {
 protected:
    std::unordered_map<const IR::Block*, cstring> blockNamePrefixMap;

 public:
    template <typename Func>
    void forAllPipeBlocks(const IR::ToplevelBlock* evaluatedProgram, Func function) {
        auto main = evaluatedProgram->getMain();
        if (!main) ::error(ErrorType::ERR_NOT_FOUND, "Program does not contain a `main` module");
        auto cparams = main->getConstructorParameters();
        int index = -1;
        for (auto param : main->constantValue) {
            index++;
            if (!param.second) continue;
            auto pipe = param.second;
            if (!pipe->is<IR::PackageBlock>()) continue;
            auto idxParam = cparams->getParameter(index);
            auto pipeName = idxParam->name;
            function(pipeName, pipe->to<IR::PackageBlock>());
        }
    }

    using ArchCounterExtern = CounterExtern<arch>;
    using CounterTraits = Helpers::CounterlikeTraits<ArchCounterExtern>;
    using ArchMeterExtern = MeterExtern<arch>;
    using MeterTraits = Helpers::CounterlikeTraits<ArchMeterExtern>;

    using Counter = p4configv1::Counter;
    using Meter = p4configv1::Meter;
    using CounterSpec = p4configv1::CounterSpec;
    using MeterSpec = p4configv1::MeterSpec;

    BFRuntimeArchHandler(ReferenceMap* refMap, TypeMap* typeMap,
                         const IR::ToplevelBlock* evaluatedProgram)
        : P4RuntimeArchHandlerCommon<arch>(refMap, typeMap, evaluatedProgram) {
        // Create a map of all blocks to their pipe names. This map will
        // be used during collect and post processing to prefix
        // table/extern instances wherever applicable with a fully qualified
        // name. This distinction is necessary when the driver looks up
        // context.json across multiple pipes for the table name
        forAllPipeBlocks(evaluatedProgram, [&](cstring pipeName, const IR::PackageBlock* pkg) {
            Helpers::forAllEvaluatedBlocks(pkg, [&](const IR::Block* block) {
                auto decl = pkg->node->to<IR::Declaration_Instance>();
                cstring blockNamePrefix = pipeName;
                if (decl) blockNamePrefix = decl->controlPlaneName();
                blockNamePrefixMap[block] = blockNamePrefix;
            });
        });
    }

    cstring getBlockNamePrefix(const IR::Block* blk) {
        if (blockNamePrefixMap.count(blk) > 0) return blockNamePrefixMap[blk];
        return "pipe";
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

    static void addP4InfoExternInstance(const P4RuntimeSymbolTableIface& symbols,
                                        P4RuntimeSymbolType typeId, cstring typeName, cstring name,
                                        const IR::IAnnotated* annotations,
                                        const ::google::protobuf::Message& message,
                                        p4configv1::P4Info* p4info, cstring pipeName = "") {
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

    boost::optional<ActionSelector> getActionSelector(const IR::ExternBlock* instance) {
        auto actionSelDecl = instance->node->to<IR::IDeclaration>();
        // to be deleted, used to support deprecated ActionSelector constructor.
        auto size = instance->getParameterValue("size");
        BUG_CHECK(size->is<IR::Constant>(), "Non-constant size");
        return ActionSelector{actionSelDecl->controlPlaneName(), size->to<IR::Constant>()->asInt(),
                              ActionSelector::defaultMaxGroupSize,
                              size->to<IR::Constant>()->asInt(),
                              actionSelDecl->to<IR::IAnnotated>()};
    }

    void addActionSelector(const P4RuntimeSymbolTableIface& symbols, p4configv1::P4Info* p4Info,
                           const ActionSelector& actionSelector, cstring pipeName = "") {
        ::dpdk::ActionSelector selector;
        selector.set_max_group_size(actionSelector.maxGroupSize);
        selector.set_num_groups(actionSelector.numGroups);
        p4configv1::ActionProfile profile;
        profile.set_size(actionSelector.size);
        auto tablesIt = this->actionProfilesRefs.find(actionSelector.name);
        if (tablesIt != this->actionProfilesRefs.end()) {
            for (const auto& table : tablesIt->second) {
                profile.add_table_ids(symbols.getId(P4RuntimeSymbolType::TABLE(), table));
                selector.add_table_ids(symbols.getId(P4RuntimeSymbolType::TABLE(), table));
            }
        }
        // We use the ActionSelector name for the action profile, and add a "_sel" suffix for
        // the action selector.
        cstring profileName = actionSelector.name;
        selector.set_action_profile_id(symbols.getId(SymbolType::ACTION_PROFILE(), profileName));
        cstring selectorName = profileName + "_sel";
        addP4InfoExternInstance(symbols, SymbolTypeDPDK::ACTION_SELECTOR(), "ActionSelector",
                                selectorName, actionSelector.annotations, selector, p4Info,
                                pipeName);
    }

    void collectExternInstance(P4RuntimeSymbolTableIface* symbols,
                               const IR::ExternBlock* externBlock) override {
        P4RuntimeArchHandlerCommon<arch>::collectExternInstance(symbols, externBlock);

        auto decl = externBlock->node->to<IR::IDeclaration>();
        if (decl == nullptr) return;
        if (externBlock->type->name == "Digest") {
            symbols->add(SymbolType::DIGEST(), decl);
        } else if (externBlock->type->name == ActionSelectorTraits<arch>::typeName()) {
            auto selName = decl->controlPlaneName() + "_sel";
            auto profName = decl->controlPlaneName();
            symbols->add(SymbolTypeDPDK::ACTION_SELECTOR(), selName);
            symbols->add(SymbolType::ACTION_PROFILE(), profName);
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

        // add pipe name prefix to the table names
        auto pipeName = getBlockNamePrefix(tableBlock);
        auto* pre = table->mutable_preamble();
        if (pre->name() == tableDeclaration->controlPlaneName())
            pre->set_name(prefix(pipeName, pre->name()));
    }

    void addExternInstance(const P4RuntimeSymbolTableIface& symbols, p4configv1::P4Info* p4info,
                           const IR::ExternBlock* externBlock) override {
        P4RuntimeArchHandlerCommon<arch>::addExternInstance(symbols, p4info, externBlock);

        auto decl = externBlock->node->to<IR::Declaration_Instance>();
        if (decl == nullptr) return;

        // DPDK control plane software requires pipe name to be prefixed to the
        // table and extern names
        cstring pipeName = getBlockNamePrefix(externBlock);

        auto p4RtTypeInfo = p4info->mutable_type_info();
        if (externBlock->type->name == "Digest") {
            auto digest = getDigest(decl, p4RtTypeInfo);
            if (digest) this->addDigest(symbols, p4info, *digest);
        } else if (externBlock->type->name == "ActionSelector") {
            auto actionSelector = getActionSelector(externBlock);
            if (actionSelector) addActionSelector(symbols, p4info, *actionSelector, pipeName);
            for (auto& extType : *p4info->mutable_action_profiles()) {
                auto* pre = extType.mutable_preamble();
                if (pre->name() == decl->controlPlaneName()) {
                    pre->set_name(prefix(pipeName, pre->name()));
                    break;
                }
            }
        } else if (externBlock->type->name == "ActionProfile") {
            for (auto& extType : *p4info->mutable_action_profiles()) {
                auto* pre = extType.mutable_preamble();
                if (pre->name() == decl->controlPlaneName()) {
                    pre->set_name(prefix(pipeName, pre->name()));
                    break;
                }
            }
        } else if (externBlock->type->name == "Meter") {
            for (auto& extType : *p4info->mutable_meters()) {
                auto* pre = extType.mutable_preamble();
                if (pre->name() == decl->controlPlaneName()) {
                    pre->set_name(prefix(pipeName, pre->name()));
                    break;
                }
            }
        } else if (externBlock->type->name == "Counter") {
            for (auto& extType : *p4info->mutable_counters()) {
                auto* pre = extType.mutable_preamble();
                if (pre->name() == decl->controlPlaneName()) {
                    pre->set_name(prefix(pipeName, pre->name()));
                    break;
                }
            }
        } else if (externBlock->type->name == "Register") {
            for (auto& extType : *p4info->mutable_registers()) {
                auto* pre = extType.mutable_preamble();
                if (pre->name() == decl->controlPlaneName()) {
                    pre->set_name(prefix(pipeName, pre->name()));
                    break;
                }
            }
        } else if (externBlock->type->name == MatchValueLookupTableExtern::typeName()) {
            auto mvl_table = getMatchValueLookupTable(externBlock);
            if (mvl_table) addMatchValueLookupTable(symbols, p4info, *mvl_table);
        }
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

class BFRuntimeArchHandlerPSA final : public BFRuntimeArchHandler<Arch::PSA> {
 public:
    BFRuntimeArchHandlerPSA(ReferenceMap* refMap, TypeMap* typeMap,
                            const IR::ToplevelBlock* evaluatedProgram)
        : BFRuntimeArchHandler(refMap, typeMap, evaluatedProgram) {}
};

class BFRuntimeArchHandlerPNA final : public BFRuntimeArchHandler<Arch::PNA> {
 public:
    BFRuntimeArchHandlerPNA(ReferenceMap* refMap, TypeMap* typeMap,
                            const IR::ToplevelBlock* evaluatedProgram)
        : BFRuntimeArchHandler(refMap, typeMap, evaluatedProgram) {}
};

/// The architecture handler builder implementation for PSA.
struct PSAArchHandlerBuilderForDPDK : public P4::ControlPlaneAPI::P4RuntimeArchHandlerBuilderIface {
    P4::ControlPlaneAPI::P4RuntimeArchHandlerIface* operator()(
        ReferenceMap* refMap, TypeMap* typeMap,
        const IR::ToplevelBlock* evaluatedProgram) const override {
        return new P4::ControlPlaneAPI::Standard::BFRuntimeArchHandlerPSA(refMap, typeMap,
                                                                          evaluatedProgram);
    }
};

/// The architecture handler builder implementation for PNA.
struct PNAArchHandlerBuilderForDPDK : public P4::ControlPlaneAPI::P4RuntimeArchHandlerBuilderIface {
    P4::ControlPlaneAPI::P4RuntimeArchHandlerIface* operator()(
        ReferenceMap* refMap, TypeMap* typeMap,
        const IR::ToplevelBlock* evaluatedProgram) const override {
        return new P4::ControlPlaneAPI::Standard::BFRuntimeArchHandlerPNA(refMap, typeMap,
                                                                          evaluatedProgram);
    }
};

}  // namespace Standard

}  // namespace ControlPlaneAPI

/** @} */ /* end group control_plane */
}  // namespace P4

#endif /* DPDK_CONTROL_PLANE_BFRUNTIME_ARCH_HANDLER_H_ */
