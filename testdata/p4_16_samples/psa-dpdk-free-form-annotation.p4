/*
Copyright 2013-present Barefoot Networks, Inc.

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

// Test free-form annotations.
@scrabble(
    - What do you get if you multiply six by nine?
    - Six by nine. Forty two.
    - That's it. That's all there is.
    - I always thought there was something fundamentally wrong with the
      universe.
    0xdeadbeef
)
header hdr {
    bit<112> field;
}

struct Header_t {
    hdr h;
}

struct Meta_t {}

parser p(packet_in b,
         out Header_t h,
         inout Meta_t m,
         in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta,
    in EMPTY_RECIRC recirc_meta) {
    state start {
        transition accept;
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout Meta_t b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}

control c(inout Header_t h, inout Meta_t m) { apply {} }

control ingress(inout Header_t h,
                inout Meta_t m,
                in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
    apply {}
}

control egressControlImpl(
    inout EMPTY_H h,
    inout Meta_t meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}


control deparser(packet_out b,out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout Header_t h,
                            in Meta_t local_metadata,
                            in psa_ingress_output_metadata_t istd) { apply {} }

control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c1,
    in Header_t d,
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

