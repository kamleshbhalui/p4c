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

struct alt_t {
    bit<1>  valid;
    bit<7>  port;
    int<8>  hashRes;
    bool    useHash;
    bit<16> type;
    bit<7>  pad;
}

struct row_t {
    alt_t alt0;
    alt_t alt1;
}

header bitvec_hdr {
    bit<1>  _row_alt0_valid0;
    bit<7>  _row_alt0_port1;
    int<8>  _row_alt0_hashRes2;
    bool    _row_alt0_useHash3;
    bit<16> _row_alt0_type4;
    bit<7>  _row_alt0_pad5;
    bit<1>  _row_alt1_valid6;
    bit<7>  _row_alt1_port7;
    int<8>  _row_alt1_hashRes8;
    bool    _row_alt1_useHash9;
    bit<16> _row_alt1_type10;
    bit<7>  _row_alt1_pad11;
}

struct local_metadata_t {
    @field_list(0) 
    bit<1>     _row0_alt0_valid0;
    @field_list(0) 
    bit<7>     _row0_alt0_port1;
    @field_list(0) 
    int<8>     _row0_alt0_hashRes2;
    @field_list(0) 
    bool       _row0_alt0_useHash3;
    @field_list(0) 
    bit<16>    _row0_alt0_type4;
    @field_list(0) 
    bit<7>     _row0_alt0_pad5;
    @field_list(0) 
    bit<1>     _row0_alt1_valid6;
    @field_list(0) 
    bit<7>     _row0_alt1_port7;
    @field_list(0) 
    int<8>     _row0_alt1_hashRes8;
    @field_list(0) 
    bool       _row0_alt1_useHash9;
    @field_list(0) 
    bit<16>    _row0_alt1_type10;
    @field_list(0) 
    bit<7>     _row0_alt1_pad11;
    bit<1>     _row1_alt0_valid12;
    bit<7>     _row1_alt0_port13;
    int<8>     _row1_alt0_hashRes14;
    bool       _row1_alt0_useHash15;
    bit<16>    _row1_alt0_type16;
    bit<7>     _row1_alt0_pad17;
    bit<1>     _row1_alt1_valid18;
    bit<7>     _row1_alt1_port19;
    int<8>     _row1_alt1_hashRes20;
    bool       _row1_alt1_useHash21;
    bit<16>    _row1_alt1_type22;
    bit<7>     _row1_alt1_pad23;
    bitvec_hdr _bvh024;
    bitvec_hdr _bvh125;
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
        h.bvh1._row_alt1_valid6 = 1w0;
        local_metadata._row0_alt0_valid0 = 1w0;
    }
    @name("ingress.tns") table tns_0 {
        key = {
            h.bvh1._row_alt1_valid6         : exact @name("h.bvh1.row.alt1.valid") ;
            local_metadata._row0_alt0_valid0: exact @name("local_metadata.row0.alt0.valid") ;
        }
        actions = {
            do_act();
            @defaultonly NoAction_1();
        }
        default_action = NoAction_1();
    }
    @hidden action psadpdkissue1653complex96() {
        bh_0.setInvalid();
    }
    @hidden action psadpdkissue1653complex119() {
        bh_0._row_alt1_type10 = 16w0x800;
        h.bvh0._row_alt1_type10 = 16w0x800;
        local_metadata._row0_alt0_useHash3 = true;
        psa_clone_i2e(ostd);
    }
    @hidden table tbl_psadpdkissue1653complex96 {
        actions = {
            psadpdkissue1653complex96();
        }
        const default_action = psadpdkissue1653complex96();
    }
    @hidden table tbl_psadpdkissue1653complex119 {
        actions = {
            psadpdkissue1653complex119();
        }
        const default_action = psadpdkissue1653complex119();
    }
    apply {
        tbl_psadpdkissue1653complex96.apply();
        tns_0.apply();
        tbl_psadpdkissue1653complex119.apply();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout local_metadata_t meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control deparser(packet_out b, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout parsed_packet_t h, in local_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {
    @hidden action psadpdkissue1653complex144() {
        b.emit<bitvec_hdr>(h.bvh0);
        b.emit<bitvec_hdr>(h.bvh1);
    }
    @hidden table tbl_psadpdkissue1653complex144 {
        actions = {
            psadpdkissue1653complex144();
        }
        const default_action = psadpdkissue1653complex144();
    }
    apply {
        tbl_psadpdkissue1653complex144.apply();
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in local_metadata_t d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<parsed_packet_t, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(parse(), ingress(), deparser()) ip;

EgressPipeline<EMPTY_H, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<parsed_packet_t, local_metadata_t, EMPTY_H, local_metadata_t, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

