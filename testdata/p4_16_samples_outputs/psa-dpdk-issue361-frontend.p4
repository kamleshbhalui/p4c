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

header H {
    bit<32> f;
}

struct my_packet {
    H h;
}

struct my_metadata {
}

parser MyParser(packet_in b, out my_packet p, inout my_metadata m, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    @name("MyParser.bv") bool bv_0;
    state start {
        bv_0 = true;
        transition start_0;
    }
    state start_0 {
        transition select(bv_0) {
            false: next;
            true: accept;
        }
    }
    state next {
        b.extract<H>(p.h);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout my_metadata b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition start_0;
    }
    state start_0 {
        transition accept;
    }
}

control MyIngress(inout my_packet p, inout my_metadata m, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    apply {
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout my_metadata meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control MyDeparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout my_packet hdr, in my_metadata local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in my_metadata d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<my_packet, my_metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(MyParser(), MyIngress(), MyDeparser()) ip;

EgressPipeline<EMPTY_H, my_metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<my_packet, my_metadata, EMPTY_H, my_metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

