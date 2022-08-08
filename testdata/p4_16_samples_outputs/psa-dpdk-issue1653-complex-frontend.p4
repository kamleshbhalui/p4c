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

enum bit<16> EthTypes {
    IPv4 = 16w0x800,
    ARP = 16w0x806,
    RARP = 16w0x8035,
    EtherTalk = 16w0x809b,
    VLAN = 16w0x8100,
    IPX = 16w0x8137,
    IPv6 = 16w0x86dd
}

struct alt_t {
    bit<1>   valid;
    bit<7>   port;
    int<8>   hashRes;
    bool     useHash;
    EthTypes type;
    bit<7>   pad;
}

struct row_t {
    alt_t alt0;
    alt_t alt1;
}

header bitvec_hdr {
    row_t row;
}

struct local_metadata_t {
    @field_list(0) 
    row_t      row0;
    row_t      row1;
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
}

struct parsed_packet_t {
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
}

parser parse(packet_in pk, out parsed_packet_t h, inout local_metadata_t local_metadata, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        pk.extract<bitvec_hdr>(h.bvh0);
        pk.extract<bitvec_hdr>(h.bvh1);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout local_metadata_t b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout parsed_packet_t h, inout local_metadata_t local_metadata, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @name("ingress.bh") bitvec_hdr bh_0;
    @noWarn("unused") @name(".NoAction") action NoAction_1() {
    }
    @name("ingress.do_act") action do_act() {
        h.bvh1.row.alt1.valid = 1w0;
        local_metadata.row0.alt0.valid = 1w0;
    }
    @name("ingress.tns") table tns_0 {
        key = {
            h.bvh1.row.alt1.valid         : exact @name("h.bvh1.row.alt1.valid") ;
            local_metadata.row0.alt0.valid: exact @name("local_metadata.row0.alt0.valid") ;
        }
        actions = {
            do_act();
            @defaultonly NoAction_1();
        }
        default_action = NoAction_1();
    }
    apply {
        bh_0.setInvalid();
        tns_0.apply();
        bh_0.row.alt1.type = EthTypes.IPv4;
        h.bvh0.row.alt1.type = bh_0.row.alt1.type;
        local_metadata.row0.alt0.useHash = true;
        psa_clone_i2e(ostd);
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout local_metadata_t meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout parsed_packet_t h, in local_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
        b.emit<bitvec_hdr>(h.bvh0);
        b.emit<bitvec_hdr>(h.bvh1);
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in local_metadata_t d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<parsed_packet_t, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(parse(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<parsed_packet_t, local_metadata_t, EMPTY_H, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

