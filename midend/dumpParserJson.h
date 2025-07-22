#ifndef MIDEND_DUMPPARSERJSON_H_
#define MIDEND_DUMPPARSERJSON_H_

#include <filesystem>

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"
#include "ir/visitor.h"

namespace P4 {

class DumpParserJson : public Inspector {
    const ReferenceMap *refMap;
    const TypeMap *typeMap;
    std::filesystem::path file;

 public:
    DumpParserJson(const ReferenceMap *refMap, const TypeMap *typeMap,
                   const std::filesystem::path &file);

 private:
    bool preorder(const IR::P4Program *program) override;
    static cstring exprName(const IR::Expression *e);
    static int fieldOffset(const IR::Type_StructLike *ht, cstring field);
    void dumpParser(const IR::P4Program *program) const;
};

}  // namespace P4

#endif /* MIDEND_DUMPPARSERJSON_H_ */
