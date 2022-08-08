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
    bool b;
    bit<32> a;
    action cond() {
        b = true;
        if (b) {
            a = 32w5;
        } else {
            a = 32w10;
        }
    }
    apply {
        cond();
    }
}

top(Ing()) main;

