/*
Copyright 2022 Intel Corporation

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
#define MAX_LAYERS 2
typedef bit<48>  EthernetAddress;

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header vlan_tag_h {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
}

struct headers_t {
    ethernet_t ethernet;
    vlan_tag_h[MAX_LAYERS]      vlan_tag;
}

struct main_metadata_t {
    bit<2> depth;
    bit<16> ethType;
}

parser ingressParserImpl(
    packet_in pkt,
    out headers_t hdrs,
    inout main_metadata_t meta,
    in psa_ingress_parser_input_metadata_t x,
    in EMPTY_RESUB resub_meta,
    in EMPTY_RECIRC recirc_meta)
{
    state start {
        meta.depth = MAX_LAYERS - 1;
        pkt.extract(hdrs.ethernet);
        transition select(hdrs.ethernet.etherType) {
            ether_type_t.TPID :  parse_vlan_tag;
            default: accept;
        }
    }
    state parse_vlan_tag {
        pkt.extract(hdrs.vlan_tag.next);
        meta.depth = meta.depth - 1;
        transition select(hdrs.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            default: accept;
        }
    }
}

parser egressParserImpl(
    packet_in buffer,
    out EMPTY_H a,
    inout main_metadata_t b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY_BRIDGE d,
    in EMPTY_CLONE e,
    in EMPTY_CLONE f) {
    state start {
        transition accept;
    }
}


control ingressControlImpl(
    inout headers_t hdrs,
    inout main_metadata_t meta,
    in psa_ingress_input_metadata_t istd,
                            inout psa_ingress_output_metadata_t ostd)
{
    action drop_packet() {
        ingress_drop(ostd);
    }
    action execute() {
        meta.ethType = hdrs.vlan_tag[meta.depth - 1].ether_type;
        hdrs.vlan_tag[meta.depth - 1].ether_type = (ether_type_t)16w2;
        hdrs.vlan_tag[meta.depth].vid = (bit<12>)hdrs.vlan_tag[meta.depth].cfi;
        hdrs.vlan_tag[meta.depth].vid = hdrs.vlan_tag[meta.depth-1].vid;
 //       hdrs.vlan_tag[meta.depth].vid = hdrs.vlan_tag[1].vid;
    }
    action execute_1() {
         drop_packet();
    }
		
    table stub {
        key = {
              hdrs.vlan_tag[meta.depth].vid : exact;
        }

        actions = {
		execute;
        }
	const default_action = execute;
        size=1000000;
    }

    table stub1 {
        key = {
              hdrs.ethernet.etherType : exact;
        }

        actions = {
		execute_1;
        }
	const default_action = execute_1;
        size=1000000;
    }
    apply {
        switch (hdrs.vlan_tag[meta.depth].vid) {
//        switch (hdrs.vlan_tag[0].vid) {
            12w1: { stub.apply();}
            12w2: {
               if (hdrs.vlan_tag[meta.depth].ether_type == hdrs.ethernet.etherType)
                   stub1.apply();
            }
        }
    }
}

control egressControlImpl(
    inout EMPTY_H hdr,
    inout main_metadata_t meta,
    in psa_egress_input_metadata_t x,
                            inout psa_egress_output_metadata_t ostd)
{
    apply { }
}

control ingressDeparserImpl(
    packet_out pkt,
    out EMPTY_CLONE clone_i2e_meta,
                            out EMPTY_RESUB resubmit_meta,
                            out EMPTY_BRIDGE normal_meta,
                            inout headers_t hdr,
                            in main_metadata_t local_metadata,
                            in psa_ingress_output_metadata_t istd )
{
    apply {
        pkt.emit(hdr.ethernet);
    }
}

control egressDeparserImpl(
    packet_out buffer,
    out EMPTY_CLONE a,
    out EMPTY_RECIRC b,
    inout EMPTY_H c,
    in main_metadata_t d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { }
}

IngressPipeline(ingressParserImpl(), ingressControlImpl(), ingressDeparserImpl()) ip; 
EgressPipeline(egressParserImpl(), egressControlImpl(), egressDeparserImpl()) ep; 

PSA_Switch(
    ip, 
    PacketReplicationEngine(),
    ep, 
    BufferingQueueingEngine()) main;
