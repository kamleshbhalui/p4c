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

struct metadata {
    bit<16> transition_taken;
}

struct headers {
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.srcAddr, hdr.ethernet.dstAddr) {
            (48w0x12f0000, 48w0x456): a1;
            (48w0x12f0000 &&& 48w0xffff0000, 48w0x456): a2;
            (48w0x12f0000, 48w0x456 &&& 48w0xfff): a3;
            (48w0x12f0000 &&& 48w0xffff0000, 48w0x456 &&& 48w0xfff): a4;
            default: a5;
        }
    }
    state a1 {
        meta.transition_taken = 16w1;
        transition accept;
    }
    state a2 {
        meta.transition_taken = 16w2;
        transition accept;
    }
    state a3 {
        meta.transition_taken = 16w3;
        transition accept;
    }
    state a4 {
        meta.transition_taken = 16w4;
        transition accept;
    }
    state a5 {
        meta.transition_taken = 16w5;
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout metadata b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @hidden action psadpdkissue995l92() {
        hdr.ethernet.etherType = meta.transition_taken;
    }
    @hidden table tbl_psadpdkissue995l92 {
        actions = {
            psadpdkissue995l92();
        }
        const default_action = psadpdkissue995l92();
    }
    apply {
        tbl_psadpdkissue995l92.apply();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout metadata meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control DeparserImpl(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers hdr, in metadata local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkissue995l113() {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
    @hidden table tbl_psadpdkissue995l113 {
        actions = {
            psadpdkissue995l113();
        }
        const default_action = psadpdkissue995l113();
    }
    apply {
        tbl_psadpdkissue995l113.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in metadata d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ParserImpl(), ingress(), DeparserImpl()) ip;

EgressPipeline<EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers, metadata, EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

