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
    bit<8> a;
    bit<8> b;
    bit<8> c;
    bit<8> d;
}

header B {
    bit<8> a;
    bit<8> b;
}

struct Headers {
    ethernet_t eth_hdr;
    H          h;
    B          b;
}

struct Meta {
}

parser p(packet_in pkt, out Headers hdr, inout Meta m, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        pkt.extract<ethernet_t>(hdr.eth_hdr);
        pkt.extract<H>(hdr.h);
        pkt.extract<B>(hdr.b);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout Meta b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout Headers h, inout Meta m, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @name("ingress.tmp_2") bit<8> tmp_2;
    @name("ingress.val_0") bit<8> val;
    @hidden action psadpdkgauntlet_short_circuit77() {
        tmp_2 = 8w1;
    }
    @hidden action psadpdkgauntlet_short_circuit77_0() {
        tmp_2 = 8w2;
    }
    @hidden action act() {
        h.b.b = val;
    }
    @hidden action psadpdkgauntlet_short_circuit77_1() {
        h.b.a = tmp_2;
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_psadpdkgauntlet_short_circuit77 {
        actions = {
            psadpdkgauntlet_short_circuit77();
        }
        const default_action = psadpdkgauntlet_short_circuit77();
    }
    @hidden table tbl_psadpdkgauntlet_short_circuit77_0 {
        actions = {
            psadpdkgauntlet_short_circuit77_0();
        }
        const default_action = psadpdkgauntlet_short_circuit77_0();
    }
    @hidden table tbl_psadpdkgauntlet_short_circuit77_1 {
        actions = {
            psadpdkgauntlet_short_circuit77_1();
        }
        const default_action = psadpdkgauntlet_short_circuit77_1();
    }
    apply {
        tbl_act.apply();
        if (8w1 != val) {
            tbl_psadpdkgauntlet_short_circuit77.apply();
        } else {
            tbl_psadpdkgauntlet_short_circuit77_0.apply();
        }
        tbl_psadpdkgauntlet_short_circuit77_1.apply();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout Meta meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout Headers h, in Meta local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkgauntlet_short_circuit95() {
        b.emit<ethernet_t>(h.eth_hdr);
        b.emit<H>(h.h);
        b.emit<B>(h.b);
    }
    @hidden table tbl_psadpdkgauntlet_short_circuit95 {
        actions = {
            psadpdkgauntlet_short_circuit95();
        }
        const default_action = psadpdkgauntlet_short_circuit95();
    }
    apply {
        tbl_psadpdkgauntlet_short_circuit95.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in Meta d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<Headers, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(p(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<Headers, Meta, EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

