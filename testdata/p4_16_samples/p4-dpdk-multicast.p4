#include <core.p4>
#include <psa.p4>

header EMPTY_H {};
struct EMPTY_RESUB {};
struct EMPTY_CLONE {};
struct EMPTY_BRIDGE {};
struct EMPTY_RECIRC {};


struct routing_metadata_t {
    bit<32> nhop_ipv4;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct metadata {
    @name("routing_metadata")
    routing_metadata_t   routing_metadata;
}

struct headers {
    @name("ethernet")
    ethernet_t ethernet;
    @name("ipv4")
    ipv4_t     ipv4;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta,  in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta,
    in EMPTY_RECIRC recirc_meta) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout metadata b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}



control ingress(inout headers hdr, inout metadata meta, in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
    @name(".bcast") action bcast() {
        ostd.multicast_group = (MulticastGroup_t)(MulticastGroupUint_t)1;
    }
    @name(".set_dmac") action set_dmac(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    @name("._drop") action _drop() {
        ingress_drop(ostd);
    }
    @name(".set_nhop") action set_nhop(bit<32> nhop_ipv4, bit<9> port) {
        meta.routing_metadata.nhop_ipv4 = nhop_ipv4;
        ostd.egress_port = (PortId_t)(PortIdUint_t)port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".set_nhop_redirect") action set_nhop_redirect(bit<32> nhop_ipv4, bit<9> port) {
        meta.routing_metadata.nhop_ipv4 = nhop_ipv4;
        ostd.egress_port = (PortId_t)(PortIdUint_t)port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name("broadcast") table broadcast {
        actions = {
            bcast;
        }
        size = 1;
    }
    @name("forward") table forward {
        actions = {
            set_dmac;
            _drop;
        }
        key = {
            meta.routing_metadata.nhop_ipv4: exact;
        }
        size = 512;
    }
    @name("ipv4_lpm") table ipv4_lpm {
        actions = {
            set_nhop;
            _drop;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 1024;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
            forward.apply();
        }
        else {
            broadcast.apply();
        }
    }
}

control egressControlImpl(
    inout EMPTY_H hdr,
    inout metadata meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control DeparserImpl(packet_out packet, out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout headers hdr,
                            in metadata local_metadata,
                            in psa_ingress_output_metadata_t istd ) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c,
    in metadata d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}

IngressPipeline(ParserImpl(), ingress(), DeparserImpl()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;
