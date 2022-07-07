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
header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header vlan_tag_h {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ether_type;
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
            16w0x8100: parse_vlan_tag;
            default: accept;
        }
    }
    state parse_vlan_tag {
        pkt.extract<vlan_tag_h>(hdrs.vlan_tag.next);
        meta.depth = meta.depth + 2w3;
        transition select(hdrs.vlan_tag.last.ether_type) {
            16w0x8100: parse_vlan_tag;
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
    bit<2> hsiVar;
    bit<12> hsVar;
    bit<2> hsiVar_0;
    bit<16> hsVar_0;
    @name("ingressControlImpl.execute") action execute_1() {
        hsiVar_0 = meta.depth + 2w3;
        if (hsiVar_0 == 2w0) {
            meta.ethType = hdrs.vlan_tag[2w0].ether_type;
        } else if (hsiVar_0 == 2w1) {
            meta.ethType = hdrs.vlan_tag[2w1].ether_type;
        } else if (hsiVar_0 >= 2w1) {
            meta.ethType = hsVar_0;
        }
        hsiVar_0 = meta.depth + 2w3;
        if (hsiVar_0 == 2w0) {
            hdrs.vlan_tag[2w0].ether_type = 16w2;
        } else if (hsiVar_0 == 2w1) {
            hdrs.vlan_tag[2w1].ether_type = 16w2;
        }
        hsiVar = meta.depth;
        if (hsiVar == 2w0) {
            hdrs.vlan_tag[2w0].vid = (bit<12>)hdrs.vlan_tag[2w0].cfi;
        } else if (hsiVar == 2w1) {
            hdrs.vlan_tag[2w1].vid = (bit<12>)hdrs.vlan_tag[2w1].cfi;
        }
        hsiVar = meta.depth;
        if (hsiVar == 2w0) {
            hsiVar_0 = meta.depth + 2w3;
            if (hsiVar_0 == 2w0) {
                hdrs.vlan_tag[2w0].vid = hdrs.vlan_tag[2w0].vid;
            } else if (hsiVar_0 == 2w1) {
                hdrs.vlan_tag[2w0].vid = hdrs.vlan_tag[2w1].vid;
            } else if (hsiVar_0 >= 2w1) {
                hdrs.vlan_tag[2w0].vid = hsVar;
            }
        } else if (hsiVar == 2w1) {
            hsiVar_0 = meta.depth + 2w3;
            if (hsiVar_0 == 2w0) {
                hdrs.vlan_tag[2w1].vid = hdrs.vlan_tag[2w0].vid;
            } else if (hsiVar_0 == 2w1) {
                hdrs.vlan_tag[2w1].vid = hdrs.vlan_tag[2w1].vid;
            } else if (hsiVar_0 >= 2w1) {
                hdrs.vlan_tag[2w1].vid = hsVar;
            }
        }
    }
    @name("ingressControlImpl.execute_1") action execute_3() {
        ostd.drop = true;
    }
    bit<12> key_0;
    @name("ingressControlImpl.stub") table stub_0 {
        key = {
            key_0: exact @name("hdrs.vlan_tag[meta.depth].vid") ;
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
    bit<12> switch_0_key;
    @hidden action switch_0_case() {
    }
    @hidden action switch_0_case_0() {
    }
    @hidden action switch_0_case_1() {
    }
    @hidden table switch_0_table {
        key = {
            switch_0_key: exact;
        }
        actions = {
            switch_0_case();
            switch_0_case_0();
            switch_0_case_1();
        }
        const default_action = switch_0_case_1();
        const entries = {
                        12w1 : switch_0_case();
                        12w2 : switch_0_case_0();
        }
    }
    @hidden action psadpdkissue3374l140() {
        switch_0_key = hdrs.vlan_tag[2w0].vid;
    }
    @hidden action psadpdkissue3374l140_0() {
        switch_0_key = hdrs.vlan_tag[2w1].vid;
    }
    @hidden action psadpdkissue3374l140_1() {
        switch_0_key = hsVar;
    }
    @hidden action psadpdkissue3374l140_2() {
        hsiVar = meta.depth;
    }
    @hidden action psadpdkissue3374l118() {
        key_0 = hdrs.vlan_tag[2w0].vid;
    }
    @hidden action psadpdkissue3374l118_0() {
        key_0 = hdrs.vlan_tag[2w1].vid;
    }
    @hidden action psadpdkissue3374l118_1() {
        key_0 = hsVar;
    }
    @hidden action psadpdkissue3374l118_2() {
        hsiVar = meta.depth;
    }
    @hidden action psadpdkissue3374l144() {
        hsiVar = meta.depth;
    }
    @hidden table tbl_psadpdkissue3374l140 {
        actions = {
            psadpdkissue3374l140_2();
        }
        const default_action = psadpdkissue3374l140_2();
    }
    @hidden table tbl_psadpdkissue3374l140_0 {
        actions = {
            psadpdkissue3374l140();
        }
        const default_action = psadpdkissue3374l140();
    }
    @hidden table tbl_psadpdkissue3374l140_1 {
        actions = {
            psadpdkissue3374l140_0();
        }
        const default_action = psadpdkissue3374l140_0();
    }
    @hidden table tbl_psadpdkissue3374l140_2 {
        actions = {
            psadpdkissue3374l140_1();
        }
        const default_action = psadpdkissue3374l140_1();
    }
    @hidden table tbl_psadpdkissue3374l118 {
        actions = {
            psadpdkissue3374l118_2();
        }
        const default_action = psadpdkissue3374l118_2();
    }
    @hidden table tbl_psadpdkissue3374l118_0 {
        actions = {
            psadpdkissue3374l118();
        }
        const default_action = psadpdkissue3374l118();
    }
    @hidden table tbl_psadpdkissue3374l118_1 {
        actions = {
            psadpdkissue3374l118_0();
        }
        const default_action = psadpdkissue3374l118_0();
    }
    @hidden table tbl_psadpdkissue3374l118_2 {
        actions = {
            psadpdkissue3374l118_1();
        }
        const default_action = psadpdkissue3374l118_1();
    }
    @hidden table tbl_psadpdkissue3374l144 {
        actions = {
            psadpdkissue3374l144();
        }
        const default_action = psadpdkissue3374l144();
    }
    apply {
        tbl_psadpdkissue3374l140.apply();
        if (hsiVar == 2w0) {
            tbl_psadpdkissue3374l140_0.apply();
        } else if (hsiVar == 2w1) {
            tbl_psadpdkissue3374l140_1.apply();
        } else if (hsiVar >= 2w1) {
            tbl_psadpdkissue3374l140_2.apply();
        }
        switch (switch_0_table.apply().action_run) {
            switch_0_case: {
                tbl_psadpdkissue3374l118.apply();
                if (hsiVar == 2w0) {
                    tbl_psadpdkissue3374l118_0.apply();
                } else if (hsiVar == 2w1) {
                    tbl_psadpdkissue3374l118_1.apply();
                } else if (hsiVar >= 2w1) {
                    tbl_psadpdkissue3374l118_2.apply();
                }
                stub_0.apply();
            }
            switch_0_case_0: {
                tbl_psadpdkissue3374l144.apply();
                if (hsiVar == 2w0 && hdrs.vlan_tag[2w0].ether_type == hdrs.ethernet.etherType) {
                    stub1_0.apply();
                } else if (hsiVar == 2w1 && hdrs.vlan_tag[2w1].ether_type == hdrs.ethernet.etherType) {
                    stub1_0.apply();
                }
            }
            switch_0_case_1: {
            }
        }
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout main_metadata_t meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control ingressDeparserImpl(packet_out pkt, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers_t hdr, in main_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkissue3374l170() {
        pkt.emit<ethernet_t>(hdr.ethernet);
    }
    @hidden table tbl_psadpdkissue3374l170 {
        actions = {
            psadpdkissue3374l170();
        }
        const default_action = psadpdkissue3374l170();
    }
    apply {
        tbl_psadpdkissue3374l170.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in main_metadata_t d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers_t, main_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ingressParserImpl(), ingressControlImpl(), ingressDeparserImpl()) ip;

EgressPipeline<EMPTY_H, main_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers_t, main_metadata_t, EMPTY_H, main_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

