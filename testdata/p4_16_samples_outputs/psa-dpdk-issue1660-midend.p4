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

struct HasBool {
    @field_list(0) 
    bool x;
}

struct parsed_packet_t {
}

struct local_metadata_t {
}

parser parse(packet_in pk, out parsed_packet_t h, inout local_metadata_t local_metadata, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout local_metadata_t b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout parsed_packet_t h, inout local_metadata_t local_metadata, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @hidden action psadpdkissue1660l46() {
        psa_clone_i2e(ostd);
    }
    @hidden table tbl_psadpdkissue1660l46 {
        actions = {
            psadpdkissue1660l46();
        }
        const default_action = psadpdkissue1660l46();
    }
    apply {
        tbl_psadpdkissue1660l46.apply();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout local_metadata_t meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout parsed_packet_t hdr, in local_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in local_metadata_t d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<parsed_packet_t, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(parse(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<parsed_packet_t, local_metadata_t, EMPTY_H, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

