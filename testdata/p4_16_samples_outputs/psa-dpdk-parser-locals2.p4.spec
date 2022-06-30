
struct Ethernet_h {
	bit<48> dstAddr
	bit<48> srcAddr
	bit<16> etherType
}

struct ipv4_t {
	bit<8> version_ihl
	bit<8> dscp_ecn
	bit<16> totalLen
	bit<16> identification
	;oldname:flag_rsvd_flag_noFrag_flag_more_fragOffset
	bit<16> flag_rsvd_flag_noFrag_flag_mo0
	bit<8> ttl
	bit<8> protocol
	bit<16> hdrChecksum
	bit<32> srcAddr
	bit<32> dstAddr
}

struct psa_ingress_output_metadata_t {
	bit<8> class_of_service
	bit<8> clone
	bit<16> clone_session_id
	bit<8> drop
	bit<8> resubmit
	bit<32> multicast_group
	bit<32> egress_port
}

struct psa_egress_output_metadata_t {
	bit<8> clone
	bit<16> clone_session_id
	bit<8> drop
}

struct psa_egress_deparser_input_metadata_t {
	bit<32> egress_port
}

header ethernet instanceof Ethernet_h
header ipv4 instanceof ipv4_t

struct mystruct1 {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<32> local_metadata_b
	bit<32> IngressParser_parser_tmp
}
metadata instanceof mystruct1

action foo args none {
	add m.local_metadata_b 0x5
	return
}

table guh {
	key {
		h.ethernet.srcAddr exact
	}
	actions {
		foo
	}
	default_action foo args none 
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.ethernet
	jmpeq PARSERI_PARSE_IPV4 h.ethernet.etherType 0x800
	jmp PARSERI_ACCEPT
	PARSERI_PARSE_IPV4 :	extract h.ipv4
	mov m.IngressParser_parser_tmp h.ipv4.version_ihl
	PARSERI_ACCEPT :	table guh
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.ethernet
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


