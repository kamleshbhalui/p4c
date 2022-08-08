
struct Hdr1 {
	bit<8> a
}

struct Hdr2 {
	bit<16> b
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

header h1 instanceof Hdr1
header u instanceof U
header h2 instanceof Hdr2

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
}
metadata instanceof Meta

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.h1
	jmpeq P_GETH1 h.h1.a 0x0
	extract h.u.h2
	jmp P_ACCEPT
	P_GETH1 :	extract h.u.h1
	P_ACCEPT :	jmpnv LABEL_END h.u.h2
	validate h.h2
	mov h.h2.b h.u.h2.b
	validate h.u.h1
	mov h.u.h1.a h.u.h2.b
	invalidate h.u.h2
	LABEL_END :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.h1
	emit h.u.h1
	emit h.u.h2
	emit h.h2
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


