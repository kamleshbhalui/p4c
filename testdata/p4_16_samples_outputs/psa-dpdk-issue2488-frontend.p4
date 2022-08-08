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
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

header H {
    bit<16> a;
}

struct Headers {
    ethernet_t eth_hdr;
}

struct Meta {
}

parser p(packet_in pkt, out Headers hdr, inout Meta m, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        pkt.extract<ethernet_t>(hdr.eth_hdr);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout Meta b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout Headers h, inout Meta m, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @name("ingress.tmp") Headers tmp;
    @name("ingress.tmp") ethernet_t tmp_0;
    @name("ingress.tmp_1") bit<48> tmp_1;
    @name("ingress.tmp_2") bit<48> tmp_2;
    @name("ingress.tmp_3") bit<48> tmp_3;
    @name("ingress.tmp_4") bit<16> tmp_4;
    @name("ingress.s_0") bit<48> s;
    @name("ingress.hasReturned") bool hasReturned;
    @name("ingress.retval") bit<48> retval;
    @name("ingress.s_1") bit<48> s_2;
    @name("ingress.hasReturned") bool hasReturned_1;
    @name("ingress.retval") bit<48> retval_1;
    apply {
        tmp_1 = h.eth_hdr.dst_addr;
        s = h.eth_hdr.dst_addr;
        hasReturned = false;
        s = 48w1;
        hasReturned = true;
        retval = 48w2;
        h.eth_hdr.dst_addr = s;
        tmp_3 = retval;
        tmp_2 = tmp_3;
        tmp_4 = 16w1;
        tmp_0.setValid();
        tmp_0 = (ethernet_t){dst_addr = tmp_1,src_addr = tmp_2,eth_type = tmp_4};
        tmp = (Headers){eth_hdr = tmp_0};
        s_2 = h.eth_hdr.dst_addr;
        hasReturned_1 = false;
        s_2 = 48w1;
        hasReturned_1 = true;
        retval_1 = 48w2;
        h.eth_hdr.dst_addr = s_2;
        h = tmp;
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout Meta meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout Headers h, in Meta local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        b.emit<Headers>(h);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in Meta d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<Headers, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(p(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<Headers, Meta, EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

