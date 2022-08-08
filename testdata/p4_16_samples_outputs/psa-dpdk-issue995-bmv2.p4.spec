




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
	bit<16> local_metadata_transition_taken
}
metadata instanceof metadata

header ethernet instanceof ethernet_t

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.ethernet
	jmpneq PARSERIMPL_START_0 h.ethernet.srcAddr 0x12f0000
	jmpneq PARSERIMPL_START_0 h.ethernet.dstAddr 0x456
	jmp PARSERIMPL_A1
	PARSERIMPL_START_0 :	mov m.tmpMask h.ethernet.srcAddr
	and m.tmpMask 0xffff0000
	jmpneq PARSERIMPL_START_1 m.tmpMask 0x12f0000
	jmpneq PARSERIMPL_START_1 h.ethernet.dstAddr 0x456
	jmp PARSERIMPL_A2
	PARSERIMPL_START_1 :	jmpneq PARSERIMPL_START_2 h.ethernet.srcAddr 0x12f0000
	mov m.tmpMask_0 h.ethernet.dstAddr
	and m.tmpMask_0 0xfff
	jmpneq PARSERIMPL_START_2 m.tmpMask_0 0x456
	jmp PARSERIMPL_A3
	PARSERIMPL_START_2 :	mov m.tmpMask_1 h.ethernet.srcAddr
	and m.tmpMask_1 0xffff0000
	jmpneq PARSERIMPL_START_3 m.tmpMask_1 0x12f0000
	mov m.tmpMask_2 h.ethernet.dstAddr
	and m.tmpMask_2 0xfff
	jmpneq PARSERIMPL_START_3 m.tmpMask_2 0x456
	jmp PARSERIMPL_A4
	PARSERIMPL_START_3 :	mov m.local_metadata_transition_taken 0x5
	jmp PARSERIMPL_ACCEPT
	PARSERIMPL_A4 :	mov m.local_metadata_transition_taken 0x4
	jmp PARSERIMPL_ACCEPT
	PARSERIMPL_A3 :	mov m.local_metadata_transition_taken 0x3
	jmp PARSERIMPL_ACCEPT
	PARSERIMPL_A2 :	mov m.local_metadata_transition_taken 0x2
	jmp PARSERIMPL_ACCEPT
	PARSERIMPL_A1 :	mov m.local_metadata_transition_taken 0x1
	PARSERIMPL_ACCEPT :	mov h.ethernet.etherType m.local_metadata_transition_taken
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.ethernet
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


