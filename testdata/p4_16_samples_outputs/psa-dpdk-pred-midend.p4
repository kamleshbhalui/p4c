#include <core.p4>
#include <bmv2/psa.p4>

header EMPTY_H {
}

struct EMPTY_RESUB {
}

struct EMPTY_CLONE {
}

struct EMPTY_BRIDGE {
}

struct EMPTY_RECIRC {
}

control empty();
package top(empty e);
control Ing() {
    @name("Ing.cond") action cond() {
    }
    @hidden table tbl_cond {
        actions = {
            cond();
        }
        const default_action = cond();
    }
    apply {
        tbl_cond.apply();
    }
}

top(Ing()) main;

