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

header hdr {
    bit<32> a;
    bit<32> b;
    bit<64> c;
}

#include "arith-skeleton-dpdk.p4"

control ingress(inout Headers h, inout Meta m, in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd) {
    action add()
    { h.h.c = (bit<64>)(h.h.a + h.h.b); ostd.egress_port = (PortId_t)(PortIdUint_t)0; }
    table t {
        actions = { add; }
        const default_action = add;
    }
    apply { t.apply(); }
}

control egressControlImpl(
    inout EMPTY_H h,
    inout Meta meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

IngressPipeline(p(), ingress(), deparser()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;


