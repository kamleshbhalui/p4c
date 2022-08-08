
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


struct M {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
}
metadata instanceof M

action NoAction args none {
	return
}

action do_something args none {
	mov m.psa_ingress_output_metadata_drop 1
	return
}

table do_something {
	key {
		m.psa_ingress_input_metadata_ingress_port exact
	}
	actions {
		do_something
		NoAction
	}
	default_action NoAction args none const
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	table do_something
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


