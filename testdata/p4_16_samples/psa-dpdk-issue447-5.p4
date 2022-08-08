#include <core.p4>
#include <psa.p4>

// Define additional error values, one of them for packets with
// incorrect IPv4 header checksums.
error {
    UnhandledIPv4Options,
    BadIPv4HeaderChecksum
}

header EMPTY_H {};
struct EMPTY_RESUB {};
struct EMPTY_CLONE {};
struct EMPTY_BRIDGE {};
struct EMPTY_RECIRC {};

header S {
    bit<32> size;
}

header H {
    varbit<32> var;
}

struct Parsed_packet {
    S s1;
    H h1;
    H h2;
}

struct Metadata {
}

parser parserI(packet_in pkt, out Parsed_packet hdr, inout Metadata meta, in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta, 
    in EMPTY_RECIRC recirc_meta) {
    state start {
        pkt.extract(hdr.s1);
        pkt.extract(hdr.h1, hdr.s1.size);
        pkt.extract(hdr.h2, hdr.s1.size);
        transition accept;
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout Metadata b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control DeparserI(packet_out packet, out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout Parsed_packet hdr,
                            in Metadata local_metadata,
                            in psa_ingress_output_metadata_t istd) {
    apply {
        packet.emit(hdr.h1);
        packet.emit(hdr.h2);
    }
}

control ingress(inout Parsed_packet hdr, inout Metadata meta, in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
    varbit<32> s;
    apply {
        // swap
        s = hdr.h1.var;
        hdr.h1.var = hdr.h2.var;
        hdr.h2.var = s;
    }
}

control egressControlImpl(
    inout EMPTY_H hdr,
    inout Metadata meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c,
    in Metadata d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}

IngressPipeline(parserI(), ingress(), DeparserI()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;
