/*
Copyright 2019 MNK Consulting, LLC.
http://mnkcg.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <psa.p4>

header EMPTY_H {};
struct EMPTY_RESUB {};
struct EMPTY_CLONE {};
struct EMPTY_BRIDGE {};
struct EMPTY_RECIRC {};


enum bit<16> EthTypes {
    IPv4 = 0x0800,
    ARP = 0x0806,
    RARP = 0x8035,
    EtherTalk = 0x809B,
    VLAN = 0x8100,
    IPX = 0x8137,
    IPv6 = 0x86DD
}

struct alt_t {
    bit<1> valid;
    bit<7> port;
    int<8> hashRes;
    bool   useHash;
    EthTypes type;
    bit<7> pad;
};

struct row_t {
    alt_t alt0;
    alt_t alt1;
};

header bitvec_hdr {
    row_t row;
}

struct local_metadata_t {
    @field_list(0)
    row_t row0;
    row_t row1;
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
};

struct parsed_packet_t {
    bitvec_hdr bvh0;
    bitvec_hdr bvh1;
};

parser parse(packet_in pk, out parsed_packet_t h,
             inout local_metadata_t local_metadata,
            in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta,
    in EMPTY_RECIRC recirc_meta) {
    state start {
	pk.extract(h.bvh0);
	pk.extract(h.bvh1);
	transition accept;
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout local_metadata_t b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control ingress(inout parsed_packet_t h,
                inout local_metadata_t local_metadata,
            in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
    bitvec_hdr bh;

    action do_act() {
        h.bvh1.row.alt1.valid = 0;
        local_metadata.row0.alt0.valid = 0;
    }

    table tns {
        key = {
            h.bvh1.row.alt1.valid : exact;
            local_metadata.row0.alt0.valid : exact;
        }
	actions = {
            do_act;
        }
    }

    apply {

        tns.apply();

        // Copy another header's data to local variable.
        bh.row.alt0.useHash = h.bvh0.row.alt0.useHash;
        bh.row.alt1.type = EthTypes.IPv4;
        h.bvh0.row.alt1.type = bh.row.alt1.type;

        local_metadata.row0.alt0.useHash = true;
        psa_clone_i2e(ostd);
    }
}

control egressControlImpl(
    inout EMPTY_H hdr,
    inout local_metadata_t meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}


control deparser(packet_out b,  out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout parsed_packet_t h,
                            in local_metadata_t local_metadata,
                            in psa_ingress_output_metadata_t istd) {
    apply {
        b.emit(h.bvh0);
        b.emit(h.bvh1);
    }
}

control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c,
    in local_metadata_t d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}
IngressPipeline(parse(), ingress(), deparser()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;
