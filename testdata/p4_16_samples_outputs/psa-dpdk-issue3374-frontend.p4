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

typedef bit<48> EthernetAddress;
enum bit<16> ether_type_t {
    TPID = 16w0x8100,
    IPV4 = 16w0x800,
    IPV6 = 16w0x86dd
}

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header vlan_tag_h {
    bit<3>       pcp;
    bit<1>       cfi;
    bit<12>      vid;
    ether_type_t ether_type;
}

struct headers_t {
    ethernet_t    ethernet;
    vlan_tag_h[2] vlan_tag;
}

struct main_metadata_t {
    bit<2>  depth;
    bit<16> ethType;
}

parser ingressParserImpl(packet_in pkt, out headers_t hdrs, inout main_metadata_t meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        meta.depth = 2w1;
        pkt.extract<ethernet_t>(hdrs.ethernet);
        transition select(hdrs.ethernet.etherType) {
            ether_type_t.TPID: parse_vlan_tag;
            default: accept;
        }
    }
    state parse_vlan_tag {
        pkt.extract<vlan_tag_h>(hdrs.vlan_tag.next);
        meta.depth = meta.depth + 2w3;
        transition select(hdrs.vlan_tag.last.ether_type) {
            ether_type_t.TPID: parse_vlan_tag;
            default: accept;
        }
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout main_metadata_t b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingressControlImpl(inout headers_t hdrs, inout main_metadata_t meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @name("ingressControlImpl.meta") psa_ingress_output_metadata_t meta_1;
    @name("ingressControlImpl.execute") action execute_1() {
        meta.ethType = hdrs.vlan_tag[meta.depth + 2w3].ether_type;
        hdrs.vlan_tag[meta.depth + 2w3].ether_type = (ether_type_t)16w2;
        hdrs.vlan_tag[meta.depth].vid = (bit<12>)hdrs.vlan_tag[meta.depth].cfi;
        hdrs.vlan_tag[meta.depth].vid = hdrs.vlan_tag[meta.depth + 2w3].vid;
    }
    @name("ingressControlImpl.execute_1") action execute_3() {
        meta_1 = ostd;
        meta_1.drop = true;
        ostd = meta_1;
    }
    @name("ingressControlImpl.stub") table stub_0 {
        key = {
            hdrs.vlan_tag[meta.depth].vid: exact @name("hdrs.vlan_tag[meta.depth].vid") ;
        }
        actions = {
            execute_1();
        }
        const default_action = execute_1();
        size = 1000000;
    }
    @name("ingressControlImpl.stub1") table stub1_0 {
        key = {
            hdrs.ethernet.etherType: exact @name("hdrs.ethernet.etherType") ;
        }
        actions = {
            execute_3();
        }
        const default_action = execute_3();
        size = 1000000;
    }
    apply {
        switch (hdrs.vlan_tag[meta.depth].vid) {
            12w1: {
                stub_0.apply();
            }
            12w2: {
                if (hdrs.vlan_tag[meta.depth].ether_type == hdrs.ethernet.etherType) {
                    stub1_0.apply();
                }
            }
        }
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout main_metadata_t meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control ingressDeparserImpl(packet_out pkt, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers_t hdr, in main_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        pkt.emit<ethernet_t>(hdr.ethernet);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in main_metadata_t d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers_t, main_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ingressParserImpl(), ingressControlImpl(), ingressDeparserImpl()) ip;

EgressPipeline<EMPTY_H, main_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers_t, main_metadata_t, EMPTY_H, main_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

