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

struct routing_metadata_t {
    bit<32> nhop_ipv4;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
}

struct metadata {
    routing_metadata_t routing_metadata;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout metadata b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    action setDest() {
        hdr.ethernet.dstAddr = 48w0x6af3400426d3;
    }
    table someTable {
        key = {
            hdr.ethernet.srcAddr: exact;
        }
        actions = {
            setDest;
        }
    }
    apply {
        bool didHit = someTable.apply().hit;
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout metadata meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control DeparserImpl(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers hdr, in metadata local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in metadata d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline(ParserImpl(), ingress(), DeparserImpl()) ip;

EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

