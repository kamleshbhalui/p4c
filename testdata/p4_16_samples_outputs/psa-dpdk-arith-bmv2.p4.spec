
struct hdr {
	bit<32> a
	bit<32> b
	bit<64> c
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

header h instanceof hdr

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<32> Ingress_tmp
}
metadata instanceof Meta

action add_1 args none {
	mov m.Ingress_tmp h.h.a
	add m.Ingress_tmp h.h.b
	mov h.h.c m.Ingress_tmp
	mov m.psa_ingress_output_metadata_egress_port 0x0
	return
}

table t {
	actions {
		add_1
	}
	default_action add_1 args none const
	size 0x10000
}


apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.h
	table t
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.h
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


