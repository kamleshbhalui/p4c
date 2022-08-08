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

parser MyParser(packet_in b, out h hdr, inout m meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    @name("MyParser.l3.etherType") bit<16> l3_etherType;
    state start {
        transition start_0;
    }
    state start_0 {
        b.extract<ethernet_t>(hdr.ether);
        transition L3_start;
    }
    state L3_start {
        l3_etherType = hdr.ether.etherType;
        transition L3_start_0;
    }
    state L3_start_0 {
        transition select(l3_etherType) {
            16w0x800: L3_h0;
            16w0x8100: L3_i;
            default: start_1;
        }
    }
    state L3_h0 {
        b.extract<H>(hdr.h);
        transition start_1;
    }
    state L3_i {
        b.extract<I>(hdr.i);
        l3_etherType = hdr.i.etherType;
        transition L3_start_0;
    }
    state start_1 {
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout m b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition start_0;
    }
    state start_0 {
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
        b.emit<h>(hdr);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in m d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<h, m, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(MyParser(), MyIngress(), MyDeparser()) ip;

EgressPipeline<EMPTY_H, m, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<h, m, EMPTY_H, m, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

