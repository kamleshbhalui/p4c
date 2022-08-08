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

struct alt_t {
    bit<1> valid;
    bit<7> port;
}

struct row_t {
    alt_t alt0;
    alt_t alt1;
}

header Hdr1 {
    bit<8> _a0;
    bit<1> _row0_alt0_valid1;
    bit<7> _row0_alt0_port2;
    bit<1> _row0_alt1_valid3;
    bit<7> _row0_alt1_port4;
    bit<1> _row1_alt0_valid5;
    bit<7> _row1_alt0_port6;
    bit<1> _row1_alt1_valid7;
    bit<7> _row1_alt1_port8;
}

header Hdr2 {
    bit<16> _b0;
    bit<1>  _row_alt0_valid1;
    bit<7>  _row_alt0_port2;
    bit<1>  _row_alt1_valid3;
    bit<7>  _row_alt1_port4;
}

header_union U {
    Hdr1 h1;
    Hdr2 h2;
}

struct Headers {
    Hdr1 h1;
    U    u;
}

struct Meta {
}

parser p(packet_in b, out Headers h, inout Meta m, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        b.extract<Hdr1>(h.h1);
        transition select(h.h1._a0) {
            8w0: getH1;
            default: getH2;
        }
    }
    state getH1 {
        b.extract<Hdr1>(h.u.h1);
        transition accept;
    }
    state getH2 {
        b.extract<Hdr2>(h.u.h2);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout Meta b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout Headers h, inout Meta m, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @hidden action psadpdkbvec_union101() {
        h.u.h2.setInvalid();
    }
    @hidden table tbl_psadpdkbvec_union101 {
        actions = {
            psadpdkbvec_union101();
        }
        const default_action = psadpdkbvec_union101();
    }
    apply {
        if (h.u.h2.isValid()) {
            tbl_psadpdkbvec_union101.apply();
        }
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout Meta meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout Headers h, in Meta local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkbvec_union122() {
        b.emit<Hdr1>(h.h1);
        b.emit<Hdr1>(h.u.h1);
        b.emit<Hdr2>(h.u.h2);
    }
    @hidden table tbl_psadpdkbvec_union122 {
        actions = {
            psadpdkbvec_union122();
        }
        const default_action = psadpdkbvec_union122();
    }
    apply {
        tbl_psadpdkbvec_union122.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in Meta d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<Headers, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(p(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<Headers, Meta, EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

