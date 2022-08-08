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
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header H {
    bit<8> a;
}

header I {
    bit<16> etherType;
}

struct h {
    ethernet_t ether;
    H          h;
    I          i;
}

struct m {
}

parser L3(packet_in b, inout h hdr) {
    bit<16> etherType = hdr.ether.etherType;
    state start {
        transition select(etherType) {
            0x800: h0;
            0x8100: i;
            default: accept;
        }
    }
    state h0 {
        b.extract(hdr.h);
        transition accept;
    }
    state i {
        b.extract(hdr.i);
        etherType = hdr.i.etherType;
        transition start;
    }
}

parser MyParser(packet_in b, out h hdr, inout m meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    L3() l3;
    state start {
        b.extract(hdr.ether);
        l3.apply(b, hdr);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout m b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control MyIngress(inout h hdr, inout m meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    apply {
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout m meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control MyDeparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout h hdr, in m local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        b.emit(hdr);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in m d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline(MyParser(), MyIngress(), MyDeparser()) ip;

EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

