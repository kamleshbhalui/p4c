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

struct headers {
}

struct metadata {
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, in psa_ingress_parser_input_metadata_t x, in EMPTY_RESUB resub_meta, in EMPTY_RECIRC recirc_meta) {
    state start {
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY_H a, inout metadata b, in psa_egress_parser_input_metadata_t c, in EMPTY_BRIDGE d, in EMPTY_CLONE e, in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control IngressImpl(inout headers hdr, inout metadata meta, in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
    @name("IngressImpl.value") bit<32> value_1;
    @name("IngressImpl.value") bit<32> value_3;
    @name("IngressImpl.hasReturned") bool hasReturned;
    @name("IngressImpl.retval") bit<32> retval;
    @name("IngressImpl.hasReturned") bool hasReturned_1;
    @name("IngressImpl.retval") bit<32> retval_1;
    @name("IngressImpl.update_value") action update_value() {
        hasReturned = false;
        hasReturned = true;
        retval = 32w1;
        value_3 = retval;
        value_1 = value_3;
    }
    apply {
        hasReturned_1 = false;
        hasReturned_1 = true;
        retval_1 = 32w1;
        update_value();
    }
}

control egressControlImpl(inout EMPTY_H hdr, inout metadata meta, in psa_egress_input_metadata_t x, inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

control DeparserImpl(packet_out packet, out EMPTY_CLONE clone_i2e_meta, out EMPTY_RESUB resubmit_meta, out EMPTY_BRIDGE normal_meta, inout headers hdr, in metadata local_metadata, in psa_ingress_output_metadata_t istd) {
    apply {
    }
}

control egressDeparserImpl(packet_out buffer, out EMPTY_CLONE a, out EMPTY_RECIRC b, inout EMPTY_H c, in metadata d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ParserImpl(), IngressImpl(), DeparserImpl()) ip;

EgressPipeline<EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RECIRC>(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep;

PSA_Switch<headers, metadata, EMPTY_H, metadata, EMPTY_BRIDGE, EMPTY_CLONE, EMPTY_CLONE, EMPTY_RESUB, EMPTY_RECIRC>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;

