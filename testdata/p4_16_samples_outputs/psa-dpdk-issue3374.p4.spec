
struct ethernet_t {
	bit<48> dstAddr
	bit<48> srcAddr
	bit<16> etherType
}

struct vlan_tag_h {
	bit<16> pcp_cfi_vid
	bit<16> ether_type
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

header ethernet instanceof ethernet_t
header vlan_tag_0 instanceof vlan_tag_h
header vlan_tag_1 instanceof vlan_tag_h


struct main_metadata_t {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<16> psa_ingress_input_metadata_parser_error
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<32> local_metadata_depth
	bit<16> local_metadata_ethType
	bit<32> Ingress_tmp
	bit<32> Ingress_tmp_0
	bit<32> Ingress_tmp_1
	bit<32> Ingress_tmp_2
	bit<32> Ingress_tmp_3
	bit<32> Ingress_tmp_4
	bit<32> Ingress_tmp_5
	bit<32> Ingress_tmp_6
	bit<32> Ingress_tmp_7
	bit<32> Ingress_tmp_8
	bit<32> Ingress_tmp_9
	bit<16> Ingress_tmp_10
	bit<32> Ingress_tmp_11
	bit<16> Ingress_tmp_12
	bit<32> Ingress_tmp_13
	bit<16> Ingress_tmp_14
	bit<16> Ingress_tmp_15
	bit<32> Ingress_tmp_16
	bit<32> Ingress_tmp_17
	bit<16> Ingress_tmp_18
	bit<16> Ingress_tmp_19
	bit<16> Ingress_tmp_20
	bit<16> Ingress_tmp_21
	bit<16> Ingress_tmp_22
	bit<32> Ingress_tmp_23
	bit<32> Ingress_tmp_24
	bit<16> Ingress_tmp_25
	bit<16> Ingress_tmp_26
	bit<16> Ingress_tmp_27
	bit<16> Ingress_tmp_28
	bit<16> Ingress_tmp_29
	bit<32> Ingress_tmp_30
	bit<16> Ingress_tmp_31
	bit<16> Ingress_tmp_32
	bit<16> Ingress_tmp_33
	bit<16> Ingress_tmp_34
	bit<16> Ingress_tmp_35
	bit<16> Ingress_tmp_36
	bit<16> Ingress_tmp_37
	bit<16> Ingress_tmp_38
	bit<16> Ingress_tmp_39
	bit<32> Ingress_tmp_40
	bit<16> Ingress_tmp_41
	bit<16> Ingress_tmp_42
	bit<16> Ingress_tmp_43
	bit<16> Ingress_tmp_44
	bit<16> Ingress_tmp_45
	bit<16> Ingress_tmp_46
	bit<16> Ingress_tmp_47
	bit<16> Ingress_tmp_48
	bit<16> Ingress_tmp_49
	bit<16> Ingress_hsVar
	bit<32> Ingress_hsVar_0
	bit<32> Ingress_key
}
metadata instanceof main_metadata_t

action execute_1 args none {
	mov m.Ingress_tmp_1 m.local_metadata_depth
	add m.Ingress_tmp_1 0x3
	jmpneq LABEL_FALSE_3 m.Ingress_tmp_1 0x0
	mov m.local_metadata_ethType h.vlan_tag_0.ether_type
	jmp LABEL_END_4
	LABEL_FALSE_3 :	mov m.Ingress_tmp_0 m.local_metadata_depth
	add m.Ingress_tmp_0 0x3
	jmpneq LABEL_FALSE_4 m.Ingress_tmp_0 0x1
	mov m.local_metadata_ethType h.vlan_tag_1.ether_type
	jmp LABEL_END_4
	LABEL_FALSE_4 :	mov m.Ingress_tmp m.local_metadata_depth
	add m.Ingress_tmp 0x3
	jmplt LABEL_END_4 m.Ingress_tmp 0x1
	mov m.local_metadata_ethType m.Ingress_hsVar
	LABEL_END_4 :	mov m.Ingress_tmp_3 m.local_metadata_depth
	add m.Ingress_tmp_3 0x3
	jmpneq LABEL_FALSE_6 m.Ingress_tmp_3 0x0
	mov h.vlan_tag_0.ether_type 0x2
	jmp LABEL_END_7
	LABEL_FALSE_6 :	mov m.Ingress_tmp_2 m.local_metadata_depth
	add m.Ingress_tmp_2 0x3
	jmpneq LABEL_END_7 m.Ingress_tmp_2 0x1
	mov h.vlan_tag_1.ether_type 0x2
	LABEL_END_7 :	jmpneq LABEL_FALSE_8 m.local_metadata_depth 0x0
	mov m.Ingress_tmp_14 h.vlan_tag_0.pcp_cfi_vid
	and m.Ingress_tmp_14 0xf
	mov m.Ingress_tmp_15 h.vlan_tag_0.pcp_cfi_vid
	shr m.Ingress_tmp_15 0x3
	mov m.Ingress_tmp_16 m.Ingress_tmp_15
	mov m.Ingress_tmp_17 m.Ingress_tmp_16
	mov m.Ingress_tmp_18 m.Ingress_tmp_17
	mov m.Ingress_tmp_19 m.Ingress_tmp_18
	shl m.Ingress_tmp_19 0x4
	mov m.Ingress_tmp_20 m.Ingress_tmp_19
	and m.Ingress_tmp_20 0xfff0
	mov h.vlan_tag_0.pcp_cfi_vid m.Ingress_tmp_14
	or h.vlan_tag_0.pcp_cfi_vid m.Ingress_tmp_20
	jmp LABEL_END_9
	LABEL_FALSE_8 :	jmpneq LABEL_END_9 m.local_metadata_depth 0x1
	mov m.Ingress_tmp_21 h.vlan_tag_1.pcp_cfi_vid
	and m.Ingress_tmp_21 0xf
	mov m.Ingress_tmp_22 h.vlan_tag_1.pcp_cfi_vid
	shr m.Ingress_tmp_22 0x3
	mov m.Ingress_tmp_23 m.Ingress_tmp_22
	mov m.Ingress_tmp_24 m.Ingress_tmp_23
	mov m.Ingress_tmp_25 m.Ingress_tmp_24
	mov m.Ingress_tmp_26 m.Ingress_tmp_25
	shl m.Ingress_tmp_26 0x4
	mov m.Ingress_tmp_27 m.Ingress_tmp_26
	and m.Ingress_tmp_27 0xfff0
	mov h.vlan_tag_1.pcp_cfi_vid m.Ingress_tmp_21
	or h.vlan_tag_1.pcp_cfi_vid m.Ingress_tmp_27
	LABEL_END_9 :	jmpneq LABEL_FALSE_10 m.local_metadata_depth 0x0
	mov m.Ingress_tmp_6 m.local_metadata_depth
	add m.Ingress_tmp_6 0x3
	jmpneq LABEL_FALSE_11 m.Ingress_tmp_6 0x0
	jmp LABEL_END_11
	LABEL_FALSE_11 :	mov m.Ingress_tmp_5 m.local_metadata_depth
	add m.Ingress_tmp_5 0x3
	jmpneq LABEL_FALSE_12 m.Ingress_tmp_5 0x1
	mov m.Ingress_tmp_28 h.vlan_tag_0.pcp_cfi_vid
	and m.Ingress_tmp_28 0xf
	mov m.Ingress_tmp_29 h.vlan_tag_1.pcp_cfi_vid
	shr m.Ingress_tmp_29 0x4
	mov m.Ingress_tmp_30 m.Ingress_tmp_29
	mov m.Ingress_tmp_31 m.Ingress_tmp_30
	mov m.Ingress_tmp_32 m.Ingress_tmp_31
	shl m.Ingress_tmp_32 0x4
	mov m.Ingress_tmp_33 m.Ingress_tmp_32
	and m.Ingress_tmp_33 0xfff0
	mov h.vlan_tag_0.pcp_cfi_vid m.Ingress_tmp_28
	or h.vlan_tag_0.pcp_cfi_vid m.Ingress_tmp_33
	jmp LABEL_END_11
	LABEL_FALSE_12 :	mov m.Ingress_tmp_4 m.local_metadata_depth
	add m.Ingress_tmp_4 0x3
	jmplt LABEL_END_11 m.Ingress_tmp_4 0x1
	mov m.Ingress_tmp_34 h.vlan_tag_0.pcp_cfi_vid
	and m.Ingress_tmp_34 0xf
	mov m.Ingress_tmp_35 m.Ingress_hsVar_0
	mov m.Ingress_tmp_36 m.Ingress_tmp_35
	shl m.Ingress_tmp_36 0x4
	mov m.Ingress_tmp_37 m.Ingress_tmp_36
	and m.Ingress_tmp_37 0xfff0
	mov h.vlan_tag_0.pcp_cfi_vid m.Ingress_tmp_34
	or h.vlan_tag_0.pcp_cfi_vid m.Ingress_tmp_37
	jmp LABEL_END_11
	LABEL_FALSE_10 :	jmpneq LABEL_END_11 m.local_metadata_depth 0x1
	mov m.Ingress_tmp_9 m.local_metadata_depth
	add m.Ingress_tmp_9 0x3
	jmpneq LABEL_FALSE_15 m.Ingress_tmp_9 0x0
	mov m.Ingress_tmp_38 h.vlan_tag_1.pcp_cfi_vid
	and m.Ingress_tmp_38 0xf
	mov m.Ingress_tmp_39 h.vlan_tag_0.pcp_cfi_vid
	shr m.Ingress_tmp_39 0x4
	mov m.Ingress_tmp_40 m.Ingress_tmp_39
	mov m.Ingress_tmp_41 m.Ingress_tmp_40
	mov m.Ingress_tmp_42 m.Ingress_tmp_41
	shl m.Ingress_tmp_42 0x4
	mov m.Ingress_tmp_43 m.Ingress_tmp_42
	and m.Ingress_tmp_43 0xfff0
	mov h.vlan_tag_1.pcp_cfi_vid m.Ingress_tmp_38
	or h.vlan_tag_1.pcp_cfi_vid m.Ingress_tmp_43
	jmp LABEL_END_11
	LABEL_FALSE_15 :	mov m.Ingress_tmp_8 m.local_metadata_depth
	add m.Ingress_tmp_8 0x3
	jmpneq LABEL_FALSE_16 m.Ingress_tmp_8 0x1
	jmp LABEL_END_11
	LABEL_FALSE_16 :	mov m.Ingress_tmp_7 m.local_metadata_depth
	add m.Ingress_tmp_7 0x3
	jmplt LABEL_END_11 m.Ingress_tmp_7 0x1
	mov m.Ingress_tmp_44 h.vlan_tag_1.pcp_cfi_vid
	and m.Ingress_tmp_44 0xf
	mov m.Ingress_tmp_45 m.Ingress_hsVar_0
	mov m.Ingress_tmp_46 m.Ingress_tmp_45
	shl m.Ingress_tmp_46 0x4
	mov m.Ingress_tmp_47 m.Ingress_tmp_46
	and m.Ingress_tmp_47 0xfff0
	mov h.vlan_tag_1.pcp_cfi_vid m.Ingress_tmp_44
	or h.vlan_tag_1.pcp_cfi_vid m.Ingress_tmp_47
	LABEL_END_11 :	return
}

action execute_3 args none {
	mov m.psa_ingress_output_metadata_drop 1
	return
}

table stub {
	key {
		m.Ingress_key exact
	}
	actions {
		execute_1
	}
	default_action execute_1 args none const
	size 0xf4240
}


table stub1 {
	key {
		h.ethernet.etherType exact
	}
	actions {
		execute_3
	}
	default_action execute_3 args none const
	size 0xf4240
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	mov m.local_metadata_depth 0x1
	extract h.ethernet
	jmpeq INGRESSPARSERIMPL_PARSE_VLAN_TAG h.ethernet.etherType 0x8100
	jmp INGRESSPARSERIMPL_ACCEPT
	INGRESSPARSERIMPL_PARSE_VLAN_TAG :	extract h.vlan_tag_0
	add m.local_metadata_depth 0x3
	jmpeq INGRESSPARSERIMPL_PARSE_VLAN_TAG1 h.vlan_tag_0.ether_type 0x8100
	jmp INGRESSPARSERIMPL_ACCEPT
	INGRESSPARSERIMPL_PARSE_VLAN_TAG1 :	extract h.vlan_tag_1
	add m.local_metadata_depth 0x3
	jmpeq INGRESSPARSERIMPL_PARSE_VLAN_TAG2 h.vlan_tag_1.ether_type 0x8100
	jmp INGRESSPARSERIMPL_ACCEPT
	INGRESSPARSERIMPL_PARSE_VLAN_TAG2 :	mov m.psa_ingress_input_metadata_parser_error 0x3
	INGRESSPARSERIMPL_ACCEPT :	jmpneq LABEL_FALSE m.local_metadata_depth 0x0
	mov m.Ingress_tmp_10 h.vlan_tag_0.pcp_cfi_vid
	shr m.Ingress_tmp_10 0x4
	mov m.Ingress_tmp_11 m.Ingress_tmp_10
	jmpeq LABEL_SWITCH m.Ingress_tmp_11 0x1
	jmpeq LABEL_SWITCH_0 m.Ingress_tmp_11 0x2
	jmp LABEL_END_0
	LABEL_SWITCH :	mov m.Ingress_tmp_48 h.vlan_tag_0.pcp_cfi_vid
	shr m.Ingress_tmp_48 0x4
	mov m.Ingress_key m.Ingress_tmp_48
	table stub
	jmp LABEL_END_0
	LABEL_SWITCH_0 :	jmpneq LABEL_END_0 h.vlan_tag_0.ether_type h.ethernet.etherType
	table stub1
	jmp LABEL_END_0
	LABEL_FALSE :	jmpneq LABEL_END_0 m.local_metadata_depth 0x1
	mov m.Ingress_tmp_12 h.vlan_tag_1.pcp_cfi_vid
	shr m.Ingress_tmp_12 0x4
	mov m.Ingress_tmp_13 m.Ingress_tmp_12
	jmpeq LABEL_SWITCH_1 m.Ingress_tmp_13 0x1
	jmpeq LABEL_SWITCH_2 m.Ingress_tmp_13 0x2
	jmp LABEL_END_0
	LABEL_SWITCH_1 :	mov m.Ingress_tmp_49 h.vlan_tag_1.pcp_cfi_vid
	shr m.Ingress_tmp_49 0x4
	mov m.Ingress_key m.Ingress_tmp_49
	table stub
	jmp LABEL_END_0
	LABEL_SWITCH_2 :	jmpneq LABEL_END_0 h.vlan_tag_1.ether_type h.ethernet.etherType
	table stub1
	LABEL_END_0 :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.ethernet
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


