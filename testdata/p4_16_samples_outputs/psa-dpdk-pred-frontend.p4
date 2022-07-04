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
    @name("Ing.b") bool b_0;
    @name("Ing.cond") action cond() {
        b_0 = true;
    }
    apply {
        cond();
    }
}

top(Ing()) main;

