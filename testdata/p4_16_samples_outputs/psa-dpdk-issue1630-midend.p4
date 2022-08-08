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

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

parser MyParser(packet_in packet, out headers hdr, inout metadata meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: ipv4;
            default: accept;
        }
    }
    state ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout metadata b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control MyIngress(inout headers hdr, inout metadata meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @noWarn("unused") @name(".NoAction") action NoAction_1() {
    }
    @name("MyIngress.drop") action drop_1() {
        ostd.drop = true;
    }
    @name("MyIngress.ipv4_forward") action ipv4_forward(@name("dstAddr") macAddr_t dstAddr_1, @name("port") PortIdUint_t port) {
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr_1;
        ostd.egress_port = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ipv4.hdrChecksum = 16w1;
    }
    @name("MyIngress.ipv4_lpm") table ipv4_lpm_0 {
        key = {
            hdr.ipv4.dstAddr: lpm @name("hdr.ipv4.dstAddr") ;
        }
        actions = {
            ipv4_forward();
            drop_1();
            NoAction_1();
        }
        size = 1024;
        default_action = NoAction_1();
    }
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm_0.apply();
        }
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout metadata meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

struct tuple_0 {
    bit<4>  f0;
    bit<4>  f1;
    bit<8>  f2;
    bit<16> f3;
    bit<16> f4;
    bit<3>  f5;
    bit<13> f6;
    bit<8>  f7;
    bit<8>  f8;
    bit<32> f9;
    bit<32> f10;
}

struct tuple_1 {
    bit<32> f0;
}

control MyDeparser(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers hdr, in metadata local_metadata, in psa_ingress_output_metadata_t istd) {
    @name("MyDeparser.ck") InternetChecksum() ck_0;
    @hidden action psadpdkissue1630l179() {
        ck_0.clear();
        ck_0.add<tuple_0>((tuple_0){f0 = hdr.ipv4.version,f1 = hdr.ipv4.ihl,f2 = hdr.ipv4.diffserv,f3 = hdr.ipv4.totalLen,f4 = hdr.ipv4.identification,f5 = hdr.ipv4.flags,f6 = hdr.ipv4.fragOffset,f7 = hdr.ipv4.ttl,f8 = hdr.ipv4.protocol,f9 = hdr.ipv4.srcAddr,f10 = hdr.ipv4.dstAddr});
        hdr.ipv4.hdrChecksum = ck_0.get();
        ck_0.clear();
        ck_0.add<tuple_1>((tuple_1){f0 = hdr.ipv4.srcAddr});
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
    }
    @hidden table tbl_psadpdkissue1630l179 {
        actions = {
            psadpdkissue1630l179();
        }
        const default_action = psadpdkissue1630l179();
    }
    apply {
        tbl_psadpdkissue1630l179.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in metadata d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(MyParser(), MyIngress(), MyDeparser()) ip;

EgressPipeline<EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers, metadata, EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

