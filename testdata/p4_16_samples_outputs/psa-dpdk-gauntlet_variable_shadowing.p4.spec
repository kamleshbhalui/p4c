
struct ethernet_t {
	bit<48> dst_addr
	bit<48> src_addr
	bit<16> eth_type
}

struct H {
	bit<32> a
	bit<32> b
	bit<8> c
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

header eth_hdr instanceof ethernet_t
header h instanceof H

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<8> local_metadata_test
	bit<32> Ingress_key
}
metadata instanceof Meta

action NoAction args none {
	return
}

action c_a_0 args none {
	mov h.h.b h.h.a
	return
}

table c_t {
	key {
		m.Ingress_key exact
	}
	actions {
		c_a_0
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	extract h.h
	mov m.local_metadata_test 0x1
	mov m.Ingress_key h.h.a
	add m.Ingress_key h.h.a
	table c_t
	mov h.h.c 0x1
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	emit h.h
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


