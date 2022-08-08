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

header test_header_t {
    bit<8> value;
}

struct headers_t {
    test_header_t[2] test;
}

struct metadata_t {
}

parser TestParser(packet_in b, out headers_t headers, inout metadata_t meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        b.extract<test_header_t>(headers.test.next);
        bit<32> test_f = headers.test.lastIndex << 1;
        transition select(test_f + 32w4294967295) {
            32w0: f;
            default: a;
        }
    }
    state a {
        transition accept;
    }
    state f {
        transition reject;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout metadata_t b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control TestIngress(inout headers_t headers, inout metadata_t meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    apply {
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout metadata_t meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control DeparserI(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers_t hdr, in metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in metadata_t d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers_t, metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(TestParser(), TestIngress(), DeparserI()) ip;

EgressPipeline<EMPTY_H, metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers_t, metadata_t, EMPTY_H, metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

