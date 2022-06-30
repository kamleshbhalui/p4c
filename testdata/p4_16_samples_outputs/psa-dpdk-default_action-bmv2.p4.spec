
struct hdr {
	bit<32> a
	bit<32> b
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

struct c_add_0_arg_t {
	bit<32> data
}

header h instanceof hdr

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
}
metadata instanceof Meta

action c_add_0 args instanceof c_add_0_arg_t {
	mov h.h.b h.h.a
	add h.h.b t.data
	return
}

table c_t {
	actions {
		c_add_0
	}
	default_action c_add_0 args data 0xa const
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.h
	table c_t
	mov m.psa_ingress_output_metadata_egress_port 0x0
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.h
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


