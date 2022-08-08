/*
Copyright 2016 VMware, Inc.

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



header hash_t {
    bit<32> hash;
}

header ipv4_t {
    bit<32> lkp_ipv4_sa;
}

struct M {
    hash_t hash;
    ipv4_t ipv4;
}

struct H { }


parser ParserI(packet_in pk, out H hdr, inout M meta, in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta,
    in EMPTY_RECIRC recirc_meta) {
    state start {
        transition accept;
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout M b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control IngressI(inout H hdr, inout M meta,in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
          Hash<bit<32>>(PSA_HashAlgorithm_t.CRC16) h;

    action a() {
          meta.hash.hash = h.get_hash((bit<32>)0,
             { meta.ipv4.lkp_ipv4_sa },
             (bit<32>)65536);
    }

    apply {
        a();
    }
}


control egressControlImpl(
    inout EMPTY_H hdr,
    inout M meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}


control DeparserI(packet_out packet,  out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout H hdr,
                            in M local_metadata,
                            in psa_ingress_output_metadata_t istd ) {
    apply { }
}


control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c,
    in M d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}


IngressPipeline(ParserI(), IngressI(), DeparserI()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;
