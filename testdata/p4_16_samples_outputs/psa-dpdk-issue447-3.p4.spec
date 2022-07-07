
struct S {
	bit<32> size
}

struct H {
	varbit<32> var
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

header s1 instanceof S
header h instanceof H
header s2 instanceof S

struct Metadata {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<32> size_extract_tmp
}
metadata instanceof Metadata

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.s1
	mov m.size_extract_tmp h.s1.size
	shr m.size_extract_tmp 0x3
	extract h.h m.size_extract_tmp
	extract h.s2
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.s2
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


