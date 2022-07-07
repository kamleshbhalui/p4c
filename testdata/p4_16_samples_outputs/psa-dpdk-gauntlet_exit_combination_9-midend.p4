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
    bool hasExited;
    @name("ingress.hasReturned") bool hasReturned;
    bit<48> key_0;
    @noWarn("unused") @name(".NoAction") action NoAction_1() {
    }
    @name("ingress.simple_action") action simple_action() {
        h.eth_hdr.src_addr = 48w1;
    }
    @name("ingress.simple_table") table simple_table_0 {
        key = {
            key_0: exact @name("Vmhbwk") ;
        }
        actions = {
            simple_action();
            @defaultonly NoAction_1();
        }
        default_action = NoAction_1();
    }
    @hidden action psadpdkgauntlet_exit_combination_9l68() {
        hasReturned = true;
    }
    @hidden action psadpdkgauntlet_exit_combination_9l58() {
        hasExited = false;
        hasReturned = false;
        key_0 = 48w1;
    }
    @hidden action psadpdkgauntlet_exit_combination_9l74() {
        h.eth_hdr.eth_type = 16w2;
        hasExited = true;
    }
    @hidden table tbl_psadpdkgauntlet_exit_combination_9l58 {
        actions = {
            psadpdkgauntlet_exit_combination_9l58();
        }
        const default_action = psadpdkgauntlet_exit_combination_9l58();
    }
    @hidden table tbl_psadpdkgauntlet_exit_combination_9l68 {
        actions = {
            psadpdkgauntlet_exit_combination_9l68();
        }
        const default_action = psadpdkgauntlet_exit_combination_9l68();
    }
    @hidden table tbl_psadpdkgauntlet_exit_combination_9l74 {
        actions = {
            psadpdkgauntlet_exit_combination_9l74();
        }
        const default_action = psadpdkgauntlet_exit_combination_9l74();
    }
    apply {
        tbl_psadpdkgauntlet_exit_combination_9l58.apply();
        switch (simple_table_0.apply().action_run) {
            simple_action: {
                tbl_psadpdkgauntlet_exit_combination_9l68.apply();
            }
            default: {
            }
        }
        if (hasReturned) {
            ;
        } else {
            tbl_psadpdkgauntlet_exit_combination_9l74.apply();
        }
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout Meta meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out pkt, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout Headers h, in Meta local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkgauntlet_exit_combination_9l97() {
        pkt.emit<ethernet_t>(h.eth_hdr);
    }
    @hidden table tbl_psadpdkgauntlet_exit_combination_9l97 {
        actions = {
            psadpdkgauntlet_exit_combination_9l97();
        }
        const default_action = psadpdkgauntlet_exit_combination_9l97();
    }
    apply {
        tbl_psadpdkgauntlet_exit_combination_9l97.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in Meta d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<Headers, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(p(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<Headers, Meta, EMPTY_H, Meta, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

