#include <deque>
#include <fstream>
#include <unordered_set>

#include "frontends/common/options.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/methodInstance.h"
#include "ir/ir.h"
#include "lib/json.h"
#include "lib/log.h"
#include "lib/nullstream.h"

using namespace P4;

static cstring exprName(const IR::Expression *e) {
    if (auto p = e->to<IR::PathExpression>()) return p->path->name;
    if (auto m = e->to<IR::Member>()) return exprName(m->expr) + "." + m->member;
    return e->toString();
}

static int fieldOffset(const IR::Type_StructLike *ht, cstring field) {
    int off = 0;
    for (auto f : ht->fields) {
        if (f->name == field) return off;
        off += f->type->width_bits();
    }
    return off;
}

int main(int argc, char *const argv[]) {
    CompilerOptions options;
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    if (options.process(argc, argv) == nullptr) return 1;
    options.setInputFile();

    AutoCompileContext context(&options);
    const IR::P4Program *program = parseP4File(options);
    if (!program || ::P4::errorCount()) return 1;

    FrontEnd fe;
    program = fe.run(options, program);
    if (!program || ::P4::errorCount()) return 1;

    ReferenceMap refMap;
    TypeMap typeMap;
    EvaluatorPass evaluator(&refMap, &typeMap);
    program->apply(evaluator);

    const IR::P4Parser *parser = nullptr;
    for (auto obj : *program) {
        if (auto p = obj->to<IR::P4Parser>()) {
            parser = p;
            break;
        }
    }
    if (parser == nullptr) {
        ::error("No parser found");
        return 1;
    }

    Util::JsonObject jsonParser;
    Util::JsonArray *statesArray = new Util::JsonArray();
    jsonParser.emplace("states", statesArray);

    std::map<cstring, unsigned> headerOffset;
    unsigned offset = 0;

    // Collect states in execution order starting from start state
    std::vector<const IR::ParserState *> ordered;
    std::unordered_set<const IR::ParserState *> visited;
    std::deque<const IR::ParserState *> work;
    const auto *startState = parser->getDeclByName(IR::ParserState::start)->to<IR::ParserState>();
    if (startState) {
        work.push_back(startState);
        visited.insert(startState);
    }
    while (!work.empty()) {
        auto st = work.front();
        work.pop_front();
        ordered.push_back(st);
        if (auto sel = st->selectExpression) {
            if (auto se = sel->to<IR::SelectExpression>()) {
                for (auto sc : se->selectCases) {
                    if (auto next = sc->state->getDecl()->to<IR::ParserState>())
                        if (visited.insert(next).second) work.push_back(next);
                }
            } else if (auto pe = sel->to<IR::PathExpression>()) {
                if (auto next = pe->getDecl()->to<IR::ParserState>())
                    if (visited.insert(next).second) work.push_back(next);
            }
        }
    }
    for (auto st : parser->states)
        if (visited.insert(st).second) ordered.push_back(st);

    std::map<const IR::ParserState *, unsigned> stateId;
    unsigned sid = 0;
    for (auto st : ordered) stateId[st] = sid++;
    jsonParser.emplace("start_state", stateId[startState]);

    for (auto st : ordered) {
        Util::JsonObject *stateJson = new Util::JsonObject();
        stateJson->emplace("id", stateId[st]);
        Util::JsonArray *transitions = new Util::JsonArray();
        stateJson->emplace("transitions", transitions);

        unsigned width = 0;
        for (auto comp : st->components) {
            if (auto mcs = comp->to<IR::MethodCallStatement>()) {
                auto mi = MethodInstance::resolve(mcs->methodCall, &refMap, &typeMap);
                if (auto ext = mi->to<ExternMethod>()) {
                    if (ext->originalExternType->name == "packet_in" &&
                        ext->method->name == "extract") {
                        auto arg = mcs->methodCall->arguments->at(0);
                        auto htype = typeMap.getType(arg->expression, true)->to<IR::Type_Header>();
                        if (!htype) continue;
                        cstring hname = exprName(arg->expression);
                        if (width == 0) {
                            Util::JsonObject *ex = new Util::JsonObject();
                            ex->emplace("offset_bits", offset);
                            stateJson->emplace("extract", ex);
                        }
                        headerOffset[hname] = offset + width;
                        width += htype->width_bits();
                    }
                }
            }
        }
        if (width > 0) {
            auto ex = stateJson->get("extract")->to<Util::JsonObject>();
            ex->emplace("width_bits", width);
        }
        if (st->name == IR::ParserState::accept) stateJson->emplace("accept", true);
        if (st->name == IR::ParserState::reject) stateJson->emplace("reject", true);

        if (auto sel = st->selectExpression) {
            if (auto se = sel->to<IR::SelectExpression>()) {
                for (auto sc : se->selectCases) {
                    if (sc->keyset->is<IR::DefaultExpression>()) {
                        stateJson->emplace("default_next_state",
                                           stateId[sc->state->getDecl()->to<IR::ParserState>()]);
                        continue;
                    }
                    auto mexpr = se->select->components.at(0);
                    if (auto mem = mexpr->to<IR::Member>()) {
                        cstring hname = exprName(mem->expr);
                        unsigned off =
                            headerOffset[hname] +
                            fieldOffset(mem->expr->type->to<IR::Type_Header>(), mem->member);
                        unsigned w = mem->type->width_bits();
                        big_int val = sc->keyset->to<IR::Constant>()->value;
                        Util::JsonArray *matchSet = new Util::JsonArray();
                        Util::JsonObject *m = new Util::JsonObject();
                        m->emplace("offset_bits", off);
                        m->emplace("width_bits", w);
                        std::stringstream ss;
                        ss << "0x" << std::hex << val;
                        m->emplace("value", ss.str());
                        std::stringstream ms;
                        ms << "0x" << std::hex << ((big_int(1) << w) - 1);
                        m->emplace("mask", ms.str());
                        matchSet->append(m);
                        Util::JsonObject *tr = new Util::JsonObject();
                        tr->emplace("match_set", matchSet);
                        tr->emplace("next_state",
                                    stateId[sc->state->getDecl()->to<IR::ParserState>()]);
                        transitions->append(tr);
                    }
                }
            } else if (auto pe = sel->to<IR::PathExpression>()) {
                stateJson->emplace("default_next_state",
                                   stateId[pe->getDecl()->to<IR::ParserState>()]);
            }
        }

        statesArray->append(stateJson);
        offset += width;
    }

    Util::JsonObject top;
    top.emplace("parser", &jsonParser);
    jsonParser.serialize(std::cout);
    return 0;
}
