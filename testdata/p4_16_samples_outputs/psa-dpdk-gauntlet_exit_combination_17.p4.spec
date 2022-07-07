
struct ethernet_t {
	bit<48> dst_addr
	bit<48> src_addr
	bit<16> eth_type
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

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<8> Ingress_hasReturned
	bit<48> Ingress_key
	bit<48> Ingress_key_0
}
metadata instanceof Meta

action NoAction args none {
	return
}

action dummy_action args none {
	return
}

action dummy_action_1 args none {
	return
}

table simple_table_1 {
	key {
		m.Ingress_key exact
	}
	actions {
		dummy_action
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


table simple_table_2 {
	key {
		m.Ingress_key_0 exact
	}
	actions {
		dummy_action_1
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	mov m.Ingress_hasReturned 0
	mov m.Ingress_key 0x1
	table simple_table_1
	jmpa LABEL_SWITCH dummy_action
	jmp LABEL_ENDSWITCH
	LABEL_SWITCH :	mov m.Ingress_key_0 0x1
	table simple_table_2
	jmpa LABEL_SWITCH_0 dummy_action_1
	jmp LABEL_ENDSWITCH
	LABEL_SWITCH_0 :	mov h.eth_hdr.src_addr 0x4
	mov m.Ingress_hasReturned 1
	LABEL_ENDSWITCH :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


