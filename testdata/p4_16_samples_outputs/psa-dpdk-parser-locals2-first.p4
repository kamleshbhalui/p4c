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
header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> totalLen;
    bit<16> identification;
    bit<1>  flag_rsvd;
    bit<1>  flag_noFrag;
    bit<1>  flag_more;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct Parsed_packet {
    Ethernet_h ethernet;
    ipv4_t     ipv4;
}

struct mystruct1 {
    bit<4> a;
    bit<4> b;
}

parser parserI(packet_in pkt, out Parsed_packet hdr, inout mystruct1 meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        bit<8> my_local = 8w1;
        pkt.extract<Ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        bit<16> my_local = 16w2;
        pkt.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.version, hdr.ipv4.protocol) {
            (4w0x4, 8w0x6): accept;
            (4w0x4, 8w0x17): accept;
            default: accept;
        }
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout mystruct1 b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control cIngress(inout Parsed_packet hdr, inout mystruct1 meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    action foo() {
        meta.b = meta.b + 4w5;
    }
    table guh {
        key = {
            hdr.ethernet.srcAddr: exact @name("hdr.ethernet.srcAddr") ;
        }
        actions = {
            foo();
        }
        default_action = foo();
    }
    apply {
        guh.apply();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout mystruct1 meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control DeparserI(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout Parsed_packet hdr, in mystruct1 local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        packet.emit<Ethernet_h>(hdr.ethernet);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in mystruct1 d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<Parsed_packet, mystruct1, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(parserI(), cIngress(), DeparserI()) ip;

EgressPipeline<EMPTY_H, mystruct1, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<Parsed_packet, mystruct1, EMPTY_H, mystruct1, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

