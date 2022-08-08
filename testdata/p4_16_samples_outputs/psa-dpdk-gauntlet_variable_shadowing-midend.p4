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

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

header H {
    bit<32> a;
    bit<32> b;
    bit<8>  c;
}

struct Headers {
    ethernet_t eth_hdr;
    H          h;
}

struct Meta {
    bit<8> test;
}

parser p(packet_in pkt, out Headers h, inout Meta m, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        pkt.extract<ethernet_t>(h.eth_hdr);
        pkt.extract<H>(h.h);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout Meta b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout Headers h, inout Meta m, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    bit<32> key_0;
    @noWarn("unused") @name(".NoAction") action NoAction_1() {
    }
    @name("ingress.c.a") action c_a_0() {
        h.h.b = h.h.a;
    }
    @name("ingress.c.t") table c_t {
        key = {
            key_0: exact @name("e") ;
        }
        actions = {
            c_a_0();
            NoAction_1();
        }
        default_action = NoAction_1();
    }
    @hidden action psadpdkgauntlet_variable_shadowing39() {
        m.test = 8w1;
        key_0 = h.h.a + h.h.a;
    }
    @hidden action psadpdkgauntlet_variable_shadowing86() {
        h.h.c = 8w1;
    }
    @hidden table tbl_psadpdkgauntlet_variable_shadowing39 {
        actions = {
            psadpdkgauntlet_variable_shadowing39();
        }
        const default_action = psadpdkgauntlet_variable_shadowing39();
    }
    @hidden table tbl_psadpdkgauntlet_variable_shadowing86 {
        actions = {
            psadpdkgauntlet_variable_shadowing86();
        }
        const default_action = psadpdkgauntlet_variable_shadowing86();
    }
    apply {
        tbl_psadpdkgauntlet_variable_shadowing39.apply();
        c_t.apply();
        tbl_psadpdkgauntlet_variable_shadowing86.apply();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout Meta meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out pkt, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout Headers h, in Meta local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkgauntlet_variable_shadowing106() {
        pkt.emit<ethernet_t>(h.eth_hdr);
        pkt.emit<H>(h.h);
    }
    @hidden table tbl_psadpdkgauntlet_variable_shadowing106 {
        actions = {
            psadpdkgauntlet_variable_shadowing106();
        }
        const default_action = psadpdkgauntlet_variable_shadowing106();
    }
    apply {
        tbl_psadpdkgauntlet_variable_shadowing106.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in Meta d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<Headers, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(p(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<Headers, Meta, EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

