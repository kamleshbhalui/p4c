/*
Copyright 2021 Intel Corp.

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

#include "dpdkContext.h"
#include "backend.h"
#include "printUtils.h"
namespace DPDK {

unsigned DpdkContextGenerator::newTableHandle = 0;
unsigned DpdkContextGenerator::newActionHandle = 0;

// Returns a unique ID for table
unsigned int DpdkContextGenerator::getNewTableHandle() {
    return table_handle_prefix | newTableHandle++;
}

// Returns a unique ID for action
unsigned int DpdkContextGenerator::getNewActionHandle() {
    return action_handle_prefix | newActionHandle++;
}

// This function collects all tables in a vector and sets the table attributes required
// by context json into a map.
void DpdkContextGenerator::CollectTablesAndSetAttributes() {
    IR::IndexedVector<IR::Declaration> selector_tables;
    IR::IndexedVector<IR::Declaration> action_data_tables;
    for (auto kv : structure->pipelines) {
        cstring direction = "";
        if (kv.first == "Ingress")
            direction = "ingress";
        else if (kv.first == "Egress")
            direction = "egress";
        auto control = kv.second->to<IR::P4Control>();
        for (auto d : control->controlLocals) {
            if (auto tbl = d->to<IR::P4Table>()) {
                struct TableAttributes tblAttr;
                tblAttr.direction = direction;
                tblAttr.controlName = control->name.originalName;
                tblAttr.externalName = tbl->controlPlaneName();
                tblAttr.tableHandle = getNewTableHandle();
                auto size = tbl->getSizeProperty();
                tblAttr.size = dpdk_default_table_size;
                if (size)
                   tblAttr.size = size->asUnsigned();
                auto hidden = tbl->annotations->getSingle(IR::Annotation::hiddenAnnotation);
                auto selector = tbl->properties->getProperty("selector");
                tblAttr.is_add_on_miss = false;
                tblAttr.idle_timeout_with_auto_delete = false;
                auto add_on_miss = tbl->properties->getProperty("add_on_miss");
                if (add_on_miss != nullptr) {
                    if (add_on_miss->value->is<IR::ExpressionValue>()) {
                        auto expr = add_on_miss->value->to<IR::ExpressionValue>()->expression;
                        if (!expr->is<IR::BoolLiteral>()) {
                            ::error(ErrorType::ERR_UNEXPECTED,
                                   "%1%: expected boolean for 'add_on_miss' property", add_on_miss);
                            return;
                        } else {
                            tblAttr.is_add_on_miss = expr->to<IR::BoolLiteral>()->value;
                        }
                    }
                }
                auto idle_timeout_with_auto_delete =
                     tbl->properties->getProperty("idle_timeout_with_auto_delete");
                if (idle_timeout_with_auto_delete != nullptr) {
                    if (idle_timeout_with_auto_delete->value->is<IR::ExpressionValue>()) {
                        auto expr =
                        idle_timeout_with_auto_delete->value->to<IR::ExpressionValue>()->expression;
                        if (!expr->is<IR::BoolLiteral>()) {
                            ::error(ErrorType::ERR_UNEXPECTED,
                            "%1%: expected boolean for 'idle_timeout_with_auto_delete' property",
                            idle_timeout_with_auto_delete);
                            return;
                         } else {
                             tblAttr.idle_timeout_with_auto_delete =
                                      expr->to<IR::BoolLiteral>()->value;
                         }
                    }
                }
                if (hidden) {
                    tblAttr.tableType = selector ? "selection" : "action";
                    tblAttr.isHidden = true;
                } else {
                    tblAttr.isHidden = false;
                    tblAttr.tableType = "match";
                    tblAttr.tableKeys = ::get(structure->key_map, kv.second->name.originalName
                                               + "_" + tbl->name.originalName);
                }
                if (!hidden)
                    tables.push_back(d);
                else if (!selector)
                    action_data_tables.push_back(d);
                else
                    selector_tables.push_back(d);
                tableAttrmap.emplace(tbl->name.originalName, tblAttr);
            }
        }
    }
    // for match value lookup tables decls
    for (auto ed :  structure->externDecls) {
        if (auto type = ed->type->to<IR::Type_Specialized>()) {
            auto externTypeName = type->baseType->path->name.name;
            if (externTypeName == "MatchValueLookupTable") {
                mvlTables.push_back(ed);
            }
        }
    }

    // Keep the compiler generated (hidden) tables at the end
    for (auto d : selector_tables)
        tables.push_back(d);
    for (auto d : action_data_tables)
        tables.push_back(d);
}

// This functions insert a single key field in the match keys array
void DpdkContextGenerator::addKeyField(
Util::JsonArray* keyJson, const cstring name, const cstring nameAnnotation,
    const IR::KeyElement *key, int position) {
    auto* keyField = new Util::JsonObject();
    cstring fieldName = name.findlast('.');
    auto instanceName = name.replace(fieldName, "");
    fieldName = fieldName.trim(".\t\n\r");
    keyField->emplace("name", nameAnnotation);
    keyField->emplace("instance_name", instanceName);
    keyField->emplace("field_name", fieldName);
    keyField->emplace("match_type", toStr(key->matchType));
    keyField->emplace("start_bit", 0);
    keyField->emplace("bit_width", key->expression->type->width_bits());
    keyField->emplace("bit_width_full", key->expression->type->width_bits());
    keyField->emplace("position", position);
    keyJson->append(keyField);
}

// This function sets the common table properties
Util::JsonObject* DpdkContextGenerator::initTableCommonJson(
    const cstring name, const struct TableAttributes & attr) {
    auto* tableJson = new Util::JsonObject();
    cstring tableName = attr.controlName + "." + name;
    tableJson->emplace("name", attr.externalName);
    tableJson->emplace("target_name", tableName);
    tableJson->emplace("direction", attr.direction);
    tableJson->emplace("handle", attr.tableHandle);
    tableJson->emplace("table_type", attr.tableType);
    tableJson->emplace("size", attr.size);
    tableJson->emplace("p4_hidden", attr.isHidden);
    tableJson->emplace("add_on_miss", attr.is_add_on_miss);
    tableJson->emplace("idle_timeout_with_auto_delete",  attr.idle_timeout_with_auto_delete);
    return tableJson;
}

// This function sets action attributes for actions in a table.
void DpdkContextGenerator::setActionAttributes(const IR::P4Table *tbl) {
    for (auto act : tbl->getActionList()->actionList) {
        struct actionAttributes attr;
        auto action_decl = refmap->getDeclaration(act->getPath())->to<IR::P4Action>();
        bool has_constant_default_action = false;
        auto prop = tbl->properties->getProperty(IR::TableProperties::defaultActionPropertyName);
        if (prop && prop->isConstant)
            has_constant_default_action = true;
        bool is_const_default_action = false;
        bool can_be_hit_action = true;
        bool is_compiler_added_action = false;
        bool can_be_default_action = !has_constant_default_action;

        // First, check for action annotations
        auto actAnnot = action_decl->annotations;
        auto table_only_annot = actAnnot->getSingle(IR::Annotation::tableOnlyAnnotation);
        auto default_only_annot = actAnnot->getSingle(IR::Annotation::defaultOnlyAnnotation);
        auto hidden = actAnnot->getSingle(IR::Annotation::hiddenAnnotation);

        if (table_only_annot) {
            can_be_default_action = false;
        }
        if (default_only_annot) {
            can_be_hit_action = false;
        }
        if (hidden) {
            is_compiler_added_action = true;
        }

        // Second, see if this action is the default action and/or constant default action
        auto default_action = tbl->getDefaultAction();
        if (default_action) {
            if (auto mc = default_action->to<IR::MethodCallExpression>()) {
                default_action = mc->method;
            }

            auto path = default_action->to<IR::PathExpression>();
            BUG_CHECK(path, "Default action path %s cannot be found", default_action);
            auto actName = refmap->getDeclaration(path->path, true)->getName();

            if (actName == act->getName()) {
                if (has_constant_default_action) {
                    can_be_default_action = true;  // this is the constant default action
                    is_const_default_action = true;
                }
            }
        }

        /* DPDK target takes a structure as parameter for Actions. So, all action
           parameters are collected into a structure by an earlier pass. */
        auto params = ::get(structure->args_struct_map, act->externalName() + "_arg_t");
        if (params)
            attr.params = params->clone();
        else
            attr.params = nullptr;

        attr.constant_default_action = is_const_default_action;
        attr.is_compiler_added_action = is_compiler_added_action;
        attr.allowed_as_hit_action = can_be_hit_action;
        attr.allowed_as_default_action = can_be_default_action;
        attr.actionHandle = getNewActionHandle();
        attr.externalName = action_decl->controlPlaneName();
        actionAttrMap.emplace(act->getName(), attr);
    }
}

// This functions updates the table attribute map entry with default action handle
// for the specified table.
void DpdkContextGenerator::setDefaultActionHandle(const IR::P4Table *table) {
    cstring default_action_name = "";
    if (table->getDefaultAction())
        default_action_name = toStr(table->getDefaultAction());

    auto tableAttr = ::get(tableAttrmap, table->name.originalName);
    for (auto action : table->getActionList()->actionList) {
        struct actionAttributes attr = ::get(actionAttrMap, action->getName());
        if (toStr(action->expression) == default_action_name) {
            tableAttr.default_action_handle = attr.actionHandle;
            // Update default table handle in existing table attribute map
            tableAttrmap.find(table->name.originalName)->second = tableAttr;
            break;
        }
    }
}

// This functions creates JSON object for immediate fields (action parameters)
void DpdkContextGenerator::addImmediateField(
Util::JsonArray* paramJson, const cstring name, int dest_start, int dest_width) {
    auto* oneParam = new Util::JsonObject();
    oneParam->emplace("param_name", name);
    oneParam->emplace("dest_start", dest_start);
    oneParam->emplace("dest_width", dest_width);
    paramJson->append(oneParam);
}

// This functions creates JSON object for match attributes of a table.
Util::JsonObject*
DpdkContextGenerator::addMatchAttributes(const IR::P4Table* table, const cstring ctrlName) {
    auto tableAttr = ::get(tableAttrmap, table->name.originalName);
    auto* match_attributes = new Util::JsonObject();
    auto* actFmtArray = new Util::JsonArray();
    auto* stageTblArray = new Util::JsonArray();
    auto* oneStageTbl = new Util::JsonObject();
    for (auto action : table->getActionList()->actionList) {
        auto* oneAction = new Util::JsonObject();
        struct actionAttributes attr = ::get(actionAttrMap, action->getName());
        auto name = action->externalName();
        if (name != "NoAction") {
            name = ctrlName + "." + name;
        }
        oneAction->emplace("action_name", name);
        oneAction->emplace("action_handle", attr.actionHandle);
        auto* immFldArray = new Util::JsonArray();
        if (attr.params) {
            int index = 0;
            int position = 0;
            int param_width = 8;   // Minimum width for dpdk action params
            for (auto param : *(attr.params)) {
                if (param->type->is<IR::Type_Bits>()) {
                    param_width = param->type->width_bits();
                } else if (!param->type->is<IR::Type_Boolean>()) {
                    BUG("Unsupported parameter type %1%", param->type);
                }
                addImmediateField(immFldArray, param->name.originalName,
                                  index/8, param_width);
                index += param_width;
                position++;
            }
        }
        oneAction->emplace("immediate_fields",immFldArray);
        actFmtArray->append(oneAction);
    }
    oneStageTbl->emplace("action_format", actFmtArray);
    stageTblArray->append(oneStageTbl);
    match_attributes->emplace("stage_tables", stageTblArray);
    return match_attributes;
}

// This function adds a single parameter to the parameters array.
void DpdkContextGenerator::addActionParam(Util::JsonArray* paramJson, const cstring name,
     int bitWidth, int position, int byte_array_index) {
    auto* oneParam = new Util::JsonObject();
    oneParam->emplace("name", name);
    oneParam->emplace("start_bit", 0);
    oneParam->emplace("bit_width", bitWidth);
    oneParam->emplace("position", position);
    oneParam->emplace("byte_array_index", byte_array_index);
    paramJson->append(oneParam);
}

// This function creates JSON objects for  actions within a table.
Util::JsonArray* DpdkContextGenerator::addActions(
const IR::P4Table * table, const cstring controlName, bool isMatch) {
    auto* actArray = new Util::JsonArray();
    for (auto action : table->getActionList()->actionList) {
        struct actionAttributes attr = ::get(actionAttrMap, action->getName());
        // Printing compiler added actions is curently not required
        if (!attr.is_compiler_added_action) {
            auto *act = new Util::JsonObject();
            auto actName = toStr(action->expression);
            auto name = action->externalName();
            if (name != "NoAction") {
                actName = controlName + "." + actName;
            } else {
                actName = name;
            }
           act->emplace("name", attr.externalName);
           act->emplace("target_name", actName);
           act->emplace("handle", attr.actionHandle);
           if (isMatch) {
               act->emplace("constant_default_action", attr.constant_default_action);
               act->emplace("is_compiler_added_action", attr.is_compiler_added_action);
               act->emplace("allowed_as_hit_action", attr.allowed_as_hit_action);
               act->emplace("allowed_as_default_action", attr.allowed_as_default_action);;
           }
           auto* paramJson = new Util::JsonArray();
           if (attr.params) {
                int index = 0;
                int position = 0;
                int param_width = 8;
                for (auto param : *(attr.params)) {
                    if (param->type->is<IR::Type_Bits>()) {
                        param_width = param->type->width_bits();
                    } else if (!param->type->is<IR::Type_Boolean>()) {
                        BUG("Unsupported parameter type %1%", param->type);
                    }
                    addActionParam(paramJson, param->name.originalName,
                                   param_width, position, index/8);
                    index += param_width;
                    position++;
                }
            }
            act->emplace("p4_parameters", paramJson);
            actArray->append(act);
        }
    }
    return actArray;
}

// This function adds the tables referred by this table.
bool DpdkContextGenerator::addRefTables(
    const cstring tbl_name, const IR::P4Table **memberTable, Util::JsonObject* tableJson) {
    bool hasActionProfileSelector = false;

    // Below empty arrays are currently required by the control plane software.
    // May be removed in future.
    tableJson->emplace("stateful_table_refs", new Util::JsonArray());
    tableJson->emplace("statistics_table_refs", new Util::JsonArray());
    tableJson->emplace("meter_table_refs", new Util::JsonArray());

    // Reference to compiler generated member table in case of action profile and action selector.
    if (structure->member_tables.count(tbl_name)) {
        auto* actionDataJson = new Util::JsonArray();
        hasActionProfileSelector = true;
        *memberTable = structure->member_tables.at(tbl_name);
        auto* actionDataField = new Util::JsonObject();
        auto tableAttr = ::get(tableAttrmap, (*memberTable)->name.originalName);
        auto tableName = tableAttr.controlName + "." + (*memberTable)->name.originalName;
        actionDataField->emplace("name", tableName);
        actionDataField->emplace("handle", tableAttr.tableHandle);
        actionDataJson->append(actionDataField);
        tableJson->emplace("action_data_table_refs", actionDataJson);
    }

    // Reference to compiler generated group table in case of action selector
    if (structure->group_tables.count(tbl_name)) {
        auto* selectionJson = new Util::JsonArray();
        hasActionProfileSelector = true;
        auto groupTable = structure->group_tables.at(tbl_name);
        auto* selectField = new Util::JsonObject();
        auto tableAttr = ::get(tableAttrmap, groupTable->name.originalName);
        auto tableName = tableAttr.controlName + "." + groupTable->name.originalName;
        selectField->emplace("name", tableName);
        selectField->emplace("handle", tableAttr.tableHandle);
        selectionJson->append(selectField);
        tableJson->emplace("selection_table_refs", selectionJson);
    }

    if (hasActionProfileSelector) {
        tableJson->emplace("action_profile", (*memberTable)->name.originalName);
    }
    return hasActionProfileSelector;
}

// Add tables to the context json
void DpdkContextGenerator::addMatchTables(Util::JsonArray* tablesJson) {
    for (auto t : tables) {
        auto tbl = t->to<IR::P4Table>();
        auto tableAttr = ::get(tableAttrmap, tbl->name.originalName);
        auto* tableJson = initTableCommonJson(tbl->name.originalName, tableAttr);
        bool hasActionProfileSelector = false;
        bool isMatchTable = tableAttr.tableType == "match";
        const IR::P4Table *memberTable = nullptr;
        if (tableAttr.tableType != "selection") {
            if (isMatchTable) {
                hasActionProfileSelector = addRefTables(tbl->name, &memberTable, tableJson);
                auto match_keys = tbl->getKey();
                if (match_keys) {
                    auto* keyJson = new Util::JsonArray();
                    int position = 0;
                    for (auto matchKeyFromPrg : tableAttr.tableKeys) {
                        addKeyField(keyJson, matchKeyFromPrg.first, matchKeyFromPrg.second,
                                    match_keys->keyElements.at(position),position);
                        position++;
                    }
                    tableJson->emplace("match_key_fields", keyJson);
                }
            }
            // If table implementation is action profile or action selector, all actions from member
            // table should be output for the base table.
            const IR::P4Table *table = nullptr;
            if (hasActionProfileSelector) {
                table = memberTable;
            } else {
                table = tbl;
            }

            setActionAttributes(table);
            setDefaultActionHandle(table);

            tableAttr = ::get(tableAttrmap, table->name.originalName);
            tableJson->emplace("actions", addActions(table, tableAttr.controlName, isMatchTable));
            if (isMatchTable) {
                tableJson->emplace("match_attributes",
                                    addMatchAttributes(table, tableAttr.controlName));
            }
            tableJson->emplace("default_action_handle", tableAttr.default_action_handle);
        } else {
            SelectionTable sel;
            sel.setAttributes(tbl, tableAttrmap);
            tableJson->emplace("max_n_groups", sel.max_n_groups);
            tableJson->emplace("max_n_members_per_group", sel.max_n_members_per_group);
            tableJson->emplace("bound_to_action_data_table_handle",
                               sel.bound_to_action_data_table_handle);
        }
      tablesJson->append(tableJson);
    }
}

void DpdkContextGenerator::UpdateMatchKeys(P4MatchLookupTableInfo* emvlut, const IR::Type* type) {
    if (type->is<IR::Type_Bits>()) {
        auto key = new MatchKeyField();
        key->name = "";
        key->isInstanceName = true;
        key->instanceName = "meta";
        key->isFieldName = true;
        key->fieldName = "key";
        key->matchType = exact;
        key->startBit = 0;
        key->bitWidth = type->to<IR::Type_Bits>()->width_bits();
        key->bitWidthFull = type->to<IR::Type_Bits>()->width_bits();
        key->index = 0;
        emvlut->keyList.push_back(key);
    }
}

void DpdkContextGenerator::UpdateImmediateFields(P4MatchLookupTableInfo* emvlut,
    const IR::Type* type) {
    int index = 0;
    int size = 0;
    if (type->is<IR::Type_Struct>()) {
        for (auto f : type->to<IR::Type_Struct>()->fields) {
            if (f->type->is<IR::Type_Bits>()) {
                auto param = new ImmediateFields();
                param->param_name = f->name.name;
                param->param_handle = index++;
                param->dest_start = size;
                auto sz = f->type->to<IR::Type_Bits>()->width_bits();
                param->bitwidth = sz;
                size += sz >> 3;
                emvlut->matchAttributes->hardware_blocks.at(0)->immediate_fields.push_back(param);
            }
       }
    }
}

void DpdkContextGenerator::ProcessMatchValueLookupTable(const IR::Declaration_Instance* d) {
    cstring ctrl_name="";
    if (d->arguments->size() < 3) {
        ::error("%1%vRequires 3 arguments, provided  %2% arguments", d->externalName(),
                d->arguments->size());
        return;
    }

    auto annotations = d->getAnnotations();
    if (annotations == nullptr) return;

    auto lut_type = annotations->getSingle(IR::Annotation::matchValueLookupTableAnnotation);
    if (lut_type == nullptr) return;
    auto resnameexpr = lut_type->expr.at(0);
    if (resnameexpr->is<IR::StringLiteral>() == false) return;

    auto resname = resnameexpr->to<IR::StringLiteral>()->value;

    /* validate resource name */
    if (resname != "mirror_profile") {
        ::error("Invalid argument '%1%' for 'mvlt_type' annotation for '%2%'"
                " it should be '%3%'.",
                resname, d->externalName(), "mirror_profile");
        return;
    }

    auto type = typemap->getType(d);
    if (type->is<IR::Type_SpecializedCanonical>() == false) return;

    auto exactMVLut = new  P4MatchLookupTableInfo();
    exactMVLut->handle = getNewTableHandle();
    exactMVLut->ctrlName = ctrl_name;
    exactMVLut->tblName = d->externalName();
    exactMVLut->p4Hidden = false;
    exactMVLut->isP4Hidden = true;
    if (d->arguments->at(0)->expression->is<IR::Constant>()) {
        exactMVLut->size = d->arguments->at(0)->expression->to<IR::Constant>()->asInt();
    } else {
        exactMVLut->size = 255;
    }
    exactMVLut->isSize = true;
    auto typelist = type->to<IR::Type_SpecializedCanonical>()->arguments;
    auto type0 =  typelist->at(0);
    if (!type0->is<IR::Type_Bits>()) {
        ::error("Invalid key type '%1%' for '%2%' 'Type_Bits' expected.", type0, d->externalName());
        return;
    }
    auto type1 = typelist->at(1);
    if (resname == "mirror_profile") {
        if (auto s = type1->to<IR::Type_Struct>()) {
            if (s->fields.size() != 2)
                ::error("mirror profile expect exactly two immediate key in %1%.", type1);
            auto fields =  s->fields;
            if (fields[0]->name != "dest_type"
                    || fields[1]->name != "dest") {
                ::error("mirror profile for expect exactly two immediate key in"
                        " %1% with name dest_type and dest.", type1);
            }
        }
    }
    auto hwblk = new LookupHwBlocks();
    hwblk->hw_resource = resname;
    hwblk->hw_resource_id = 0;
    exactMVLut->matchAttributes = new LookupMatchAttributes();
    exactMVLut->matchAttributes->hardware_blocks.push_back(hwblk);
    UpdateMatchKeys(exactMVLut, type0);
    UpdateImmediateFields(exactMVLut, type1);
    contextLutTables.push_back(exactMVLut);
}

void DpdkContextGenerator::outputImmediateField(Util::JsonArray* immFields,
        ImmediateFields* immfld) {
    auto* immField = new Util::JsonObject();
    immField->emplace("param_name", immfld->param_name);
    immField->emplace("param_handle", immfld->param_handle);
    immField->emplace("dest_start", immfld->dest_start);
    immField->emplace("bitwidth", immfld->bitwidth);
    immFields->append(immField);
}

void DpdkContextGenerator::outputKeys(Util::JsonObject* keyJsonObj,
    std::vector<struct MatchKeyField*> &keylist, bool isLut) {
    auto* keyJsons = new Util::JsonArray();
    keyJsonObj->emplace("match_key_fields", keyJsons);

    for (auto keyInfo : keylist) {
        auto* keyJson = new Util::JsonObject();
        keyJsons->append(keyJson);
        keyJson->emplace("name", keyInfo->name);
        if (keyInfo->isInstanceName) {
            keyJson->emplace("instance_name", keyInfo->instanceName);
        }
        if (keyInfo->isFieldName) {
            keyJson->emplace("field_name", keyInfo->fieldName);
        }
        if (keyInfo->matchType == exact) {
            keyJson->emplace("match_type", "exact");
        } else if (keyInfo->matchType == ternary) {
            keyJson->emplace("match_type", "ternary");
        } else if (keyInfo->matchType == lpm) {
            keyJson->emplace("match_type", "lpm");
        } else if (keyInfo->matchType == range) {
            keyJson->emplace("match_type", "range");
        } else if (keyInfo->matchType == selector) {
            keyJson->emplace("match_type", "selector");
        }
        keyJson->emplace("start_bit", keyInfo->startBit);
        keyJson->emplace(isLut ? "dest_width" : "bit_width", keyInfo->bitWidth);
        keyJson->emplace("bit_width_full", keyInfo->bitWidthFull);
        keyJson->emplace("index", keyInfo->index);
        keyJson->emplace("position", keyInfo->position);
    }
}

void DpdkContextGenerator::outputLutMatchAttributes(Util::JsonObject* matchJsons,
     struct P4MatchLookupTableInfo* tblInfo) {
    auto* matchAttr0 = new Util::JsonObject();
    auto* matchAttrs = new Util::JsonArray();
    matchJsons->emplace("match_attributes", matchAttr0);
    matchAttr0->emplace("hardware_blocks", matchAttrs);
    if (tblInfo->matchAttributes != nullptr) {
        for (auto hwBlock : tblInfo->matchAttributes->hardware_blocks) {
            auto* matchAttr = new Util::JsonObject();
            matchAttr->emplace("hw_resource", hwBlock->hw_resource);
            matchAttr->emplace("hw_resource_id", hwBlock->hw_resource_id);
            auto* immFields = new Util::JsonArray();
            matchAttr->emplace("immediate_fields", immFields);
            for (auto immfld : hwBlock->immediate_fields) {
                outputImmediateField(immFields, immfld);
            }
            matchAttrs->append(matchAttr);
        }
    }
}

void DpdkContextGenerator::outputLutTable(Util::JsonArray* tablesJson) {
    for (auto tbl : contextLutTables) {
        auto* tableJson = new Util::JsonObject();
        tableJson->emplace("table_type", "MatchValueLookupTable");
        tableJson->emplace("handle", tbl->handle);
        tableJson->emplace("name", tbl->tblName);
        if (tbl->isSize) {
            tableJson->emplace("size", tbl->size);
        }
        if (tbl->isP4Hidden) {
            tableJson->emplace("p4_hidden", tbl->p4Hidden);
        }
        tablesJson->append(tableJson);
        outputKeys(tableJson, tbl->keyList, true);
        outputLutMatchAttributes(tableJson, tbl);
    }
}

// Add match value lookup tables to the context json
void DpdkContextGenerator::addMatchValueLookupTables(Util::JsonArray* tablesJson) {
    for (auto tbl : mvlTables) {
        ProcessMatchValueLookupTable(tbl);
    }
    outputLutTable(tablesJson);
}


const Util::JsonObject* DpdkContextGenerator::genContextJsonObject() {
    auto* json = new Util::JsonObject();
    auto* tablesJson = new Util::JsonArray();
    struct TopLevelCtxt tlinfo;
    tlinfo.initTopLevelCtxt(options);
    json->emplace("program_name", tlinfo.progName);
    json->emplace("build_date", tlinfo.buildDate);
    json->emplace("compile_command", tlinfo.compileCommand);
    json->emplace("compiler_version", tlinfo.compilerVersion);
    json->emplace("schema_version", cstring("0.1"));
    json->emplace("target", cstring("DPDK"));
    json->emplace("tables", tablesJson);
    addMatchTables(tablesJson);
    addMatchValueLookupTables(tablesJson);
    return json;
}

void DpdkContextGenerator::serializeContextJson(std::ostream* destination) {
    CollectTablesAndSetAttributes();
    auto* json = genContextJsonObject();
    json->serialize(*destination);
    destination->flush();
}

}  // namespace DPDK
