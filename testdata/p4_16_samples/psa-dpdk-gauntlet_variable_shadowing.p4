#include <core.p4>
#include <psa.p4>

header EMPTY_H {};
struct EMPTY_RESUB {};
struct EMPTY_CLONE {};
struct EMPTY_BRIDGE {};
struct EMPTY_RECIRC {};



header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

header H {
    bit<32> a;
    bit<32> b;
    bit<8> c;
}

struct Headers {
    ethernet_t eth_hdr;
    H h;
}

struct Meta {
    bit<8> test;
}

control compute(inout H h) {
    @name("a") action a_0() {
        h.b = h.a;
    }
    @name("t") table t_0 {
        key = {
            h.a + h.a: exact @name("e") ;
        }
        actions = {
            a_0();
            NoAction();
        }
        default_action = NoAction();
    }
    apply {
        bit<8> tmp = 0;
        Meta m = {0};
        t_0.apply();
        tmp = 0;
    }
}


parser p(packet_in pkt, out Headers h, inout Meta m,  in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta,
    in EMPTY_RECIRC recirc_meta) {
    state start {
        pkt.extract(h.eth_hdr);
        pkt.extract<H>(h.h);
        transition accept;
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout Meta b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout Headers h, inout Meta m, in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
    @name("c") compute() c_0;
    apply {
        m.test = 1;
        bit<8> tmp = 1;
        c_0.apply(h.h);
        h.h.c = tmp;
    }
}

control egressControlImpl(
    inout EMPTY_H hdr,
    inout Meta meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control deparser(packet_out pkt,out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout Headers h,
                            in Meta local_metadata,
                            in psa_ingress_output_metadata_t istd) {
    apply {
        pkt.emit(h);
    }
}

control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c,
    in Meta d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}

IngressPipeline(p(), ingress(), deparser()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;
