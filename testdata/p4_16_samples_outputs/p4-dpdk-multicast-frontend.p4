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
    routing_metadata_t routing_metadata;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("ipv4") 
    ipv4_t     ipv4;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    @name("ParserImpl.parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("ParserImpl.parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition accept;
    }
    @name("ParserImpl.start") state start {
        transition parse_ethernet;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout metadata b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @name("ingress.meta") psa_ingress_output_metadata_t meta_1;
    @name("ingress.meta") psa_ingress_output_metadata_t meta_3;
    @noWarn("unused") @name(".NoAction") action NoAction_1() {
    }
    @noWarn("unused") @name(".NoAction") action NoAction_2() {
    }
    @noWarn("unused") @name(".NoAction") action NoAction_3() {
    }
    @name(".bcast") action bcast() {
        ostd.multicast_group = (MulticastGroup_t)32w1;
    }
    @name(".set_dmac") action set_dmac(@name("dmac") bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    @name("._drop") action _drop() {
        meta_1 = ostd;
        meta_1.drop = true;
        ostd = meta_1;
    }
    @name("._drop") action _drop_1() {
        meta_3 = ostd;
        meta_3.drop = true;
        ostd = meta_3;
    }
    @name(".set_nhop") action set_nhop(@name("nhop_ipv4") bit<32> nhop_ipv4_1, @name("port") bit<9> port) {
        meta.routing_metadata.nhop_ipv4 = nhop_ipv4_1;
        ostd.egress_port = (PortId_t)(PortIdUint_t)port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name("ingress.broadcast") table broadcast_0 {
        actions = {
            bcast();
            @defaultonly NoAction_1();
        }
        size = 1;
        default_action = NoAction_1();
    }
    @name("ingress.forward") table forward_0 {
        actions = {
            set_dmac();
            _drop();
            @defaultonly NoAction_2();
        }
        key = {
            meta.routing_metadata.nhop_ipv4: exact @name("meta.routing_metadata.nhop_ipv4") ;
        }
        size = 512;
        default_action = NoAction_2();
    }
    @name("ingress.ipv4_lpm") table ipv4_lpm_0 {
        actions = {
            set_nhop();
            _drop_1();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.ipv4.dstAddr: lpm @name("hdr.ipv4.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction_3();
    }
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm_0.apply();
            forward_0.apply();
        } else {
            broadcast_0.apply();
        }
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout metadata meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control DeparserImpl(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers hdr, in metadata local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in metadata d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ParserImpl(), ingress(), DeparserImpl()) ip;

EgressPipeline<EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers, metadata, EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

