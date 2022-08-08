
struct ethernet_t {
	bit<48> dstAddr
	bit<48> srcAddr
	bit<16> etherType
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

struct metadata {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<16> local_metadata__fwd_meta_tmp0
	bit<32> local_metadata__fwd_meta_x11
	bit<16> local_metadata__fwd_meta_x22
	bit<32> local_metadata__fwd_meta_x33
	bit<32> local_metadata__fwd_meta_x44
	bit<16> local_metadata__fwd_meta_exp_etherType5
	bit<32> local_metadata__fwd_meta_exp_x16
	bit<16> local_metadata__fwd_meta_exp_x27
	bit<32> local_metadata__fwd_meta_exp_x38
	bit<32> local_metadata__fwd_meta_exp_x49
	bit<48> ingress_debug_table_cksum1_ethernet_srcAddr
	bit<48> ingress_debug_table_cksum1_ethernet_dstAddr
	bit<16> ingress_debug_table_cksum1_ethernet_etherType
	bit<16> Ingress_tmp
	bit<32> Ingress_tmp_0
	bit<16> Ingress_tmp_1
	bit<32> Ingress_tmp_2
	bit<32> Ingress_tmp_3
	bit<16> Ingress_tmp_4
	bit<16> Ingress_tmp_5
	bit<32> Ingress_tmp_6
	bit<16> Ingress_tmp_7
	bit<16> Ingress_tmp_8
	bit<16> Ingress_tmp_9
	bit<32> Ingress_tmp_10
	bit<32> Ingress_tmp_11
	bit<32> Ingress_tmp_12
	bit<16> Ingress_tmp_13
	bit<16> Ingress_tmp_14
	bit<32> Ingress_tmp_15
	bit<32> Ingress_tmp_16
	bit<16> Ingress_tmp_17
	bit<16> Ingress_tmp_18
	bit<32> Ingress_tmp_19
	bit<16> Ingress_tmp_20
	bit<16> Ingress_tmp_21
	bit<32> Ingress_tmp_22
	bit<48> Ingress_tmp_23
	bit<48> Ingress_tmp_24
	bit<48> Ingress_tmp_25
	bit<48> Ingress_tmp_26
	bit<48> Ingress_tmp_27
}
metadata instanceof metadata

header ethernet instanceof ethernet_t

action NoAction args none {
	return
}

table debug_table_cksum1 {
	key {
		m.ingress_debug_table_cksum1_ethernet_srcAddr exact
		m.ingress_debug_table_cksum1_ethernet_dstAddr exact
		m.ingress_debug_table_cksum1_ethernet_etherType exact
		m.local_metadata__fwd_meta_exp_etherType5 exact
		m.local_metadata__fwd_meta_tmp0 exact
		m.local_metadata__fwd_meta_exp_x16 exact
		m.local_metadata__fwd_meta_x11 exact
		m.local_metadata__fwd_meta_exp_x27 exact
		m.local_metadata__fwd_meta_x22 exact
		m.local_metadata__fwd_meta_exp_x38 exact
		m.local_metadata__fwd_meta_x33 exact
		m.local_metadata__fwd_meta_exp_x49 exact
		m.local_metadata__fwd_meta_x44 exact
	}
	actions {
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.ethernet
	compl m.local_metadata__fwd_meta_tmp0 h.ethernet.etherType
	compl m.Ingress_tmp_13 h.ethernet.etherType
	mov m.local_metadata__fwd_meta_x11 m.Ingress_tmp_13
	compl m.Ingress_tmp_14 h.ethernet.etherType
	mov m.Ingress_tmp_15 m.Ingress_tmp_14
	mov m.Ingress_tmp_16 m.Ingress_tmp_15
	shr m.Ingress_tmp_16 0x10
	mov m.Ingress_tmp_17 m.Ingress_tmp_16
	compl m.Ingress_tmp_18 h.ethernet.etherType
	mov m.Ingress_tmp_19 m.Ingress_tmp_18
	mov m.Ingress_tmp_20 m.Ingress_tmp_19
	mov m.local_metadata__fwd_meta_x22 m.Ingress_tmp_17
	add m.local_metadata__fwd_meta_x22 m.Ingress_tmp_20
	compl m.Ingress_tmp_21 h.ethernet.etherType
	mov m.local_metadata__fwd_meta_x33 m.Ingress_tmp_21
	mov m.Ingress_tmp_22 h.ethernet.etherType
	compl m.local_metadata__fwd_meta_x44 m.Ingress_tmp_22
	mov m.local_metadata__fwd_meta_exp_etherType5 0x800
	mov m.local_metadata__fwd_meta_exp_x16 0xf7ff
	mov m.local_metadata__fwd_meta_exp_x27 0xf7ff
	mov m.local_metadata__fwd_meta_exp_x38 0xf7ff
	mov m.local_metadata__fwd_meta_exp_x49 0xfffff7ff
	mov h.ethernet.dstAddr 0x0
	jmpeq LABEL_END h.ethernet.etherType 0x800
	mov m.Ingress_tmp_23 h.ethernet.dstAddr
	and m.Ingress_tmp_23 0xffffffffff
	mov h.ethernet.dstAddr m.Ingress_tmp_23
	or h.ethernet.dstAddr 0x10000000000
	LABEL_END :	compl m.Ingress_tmp h.ethernet.etherType
	mov m.Ingress_tmp_0 m.Ingress_tmp
	jmpeq LABEL_END_0 m.Ingress_tmp_0 0xf7ff
	mov m.Ingress_tmp_24 h.ethernet.dstAddr
	and m.Ingress_tmp_24 0xff00ffffffff
	mov h.ethernet.dstAddr m.Ingress_tmp_24
	or h.ethernet.dstAddr 0x100000000
	LABEL_END_0 :	compl m.Ingress_tmp_1 h.ethernet.etherType
	mov m.Ingress_tmp_2 m.Ingress_tmp_1
	mov m.Ingress_tmp_3 m.Ingress_tmp_2
	shr m.Ingress_tmp_3 0x10
	mov m.Ingress_tmp_4 m.Ingress_tmp_3
	compl m.Ingress_tmp_5 h.ethernet.etherType
	mov m.Ingress_tmp_6 m.Ingress_tmp_5
	mov m.Ingress_tmp_7 m.Ingress_tmp_6
	mov m.Ingress_tmp_8 m.Ingress_tmp_4
	add m.Ingress_tmp_8 m.Ingress_tmp_7
	jmpeq LABEL_END_1 m.Ingress_tmp_8 0xf7ff
	mov m.Ingress_tmp_25 h.ethernet.dstAddr
	and m.Ingress_tmp_25 0xffff00ffffff
	mov h.ethernet.dstAddr m.Ingress_tmp_25
	or h.ethernet.dstAddr 0x1000000
	LABEL_END_1 :	compl m.Ingress_tmp_9 h.ethernet.etherType
	mov m.Ingress_tmp_10 m.Ingress_tmp_9
	jmpeq LABEL_END_2 m.Ingress_tmp_10 0xf7ff
	mov m.Ingress_tmp_26 h.ethernet.dstAddr
	and m.Ingress_tmp_26 0xffffff00ffff
	mov h.ethernet.dstAddr m.Ingress_tmp_26
	or h.ethernet.dstAddr 0x10000
	LABEL_END_2 :	mov m.Ingress_tmp_11 h.ethernet.etherType
	compl m.Ingress_tmp_12 m.Ingress_tmp_11
	jmpeq LABEL_END_3 m.Ingress_tmp_12 0xfffff7ff
	mov m.Ingress_tmp_27 h.ethernet.dstAddr
	and m.Ingress_tmp_27 0xffffffff00ff
	mov h.ethernet.dstAddr m.Ingress_tmp_27
	or h.ethernet.dstAddr 0x100
	LABEL_END_3 :	mov m.ingress_debug_table_cksum1_ethernet_srcAddr h.ethernet.srcAddr
	mov m.ingress_debug_table_cksum1_ethernet_dstAddr h.ethernet.dstAddr
	mov m.ingress_debug_table_cksum1_ethernet_etherType h.ethernet.etherType
	table debug_table_cksum1
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.ethernet
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


