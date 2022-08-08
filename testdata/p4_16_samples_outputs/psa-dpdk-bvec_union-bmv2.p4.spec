
struct Hdr1 {
	bit<8> _a0
	;oldname:_row0_alt0_valid1__row0_alt0_port2
	bit<8> _row0_alt0_valid1__row0_alt0_0
	;oldname:_row0_alt1_valid3__row0_alt1_port4
	bit<8> _row0_alt1_valid3__row0_alt1_1
	;oldname:_row1_alt0_valid5__row1_alt0_port6
	bit<8> _row1_alt0_valid5__row1_alt0_2
	;oldname:_row1_alt1_valid7__row1_alt1_port8
	bit<8> _row1_alt1_valid7__row1_alt1_3
}

struct Hdr2 {
	bit<16> _b0
	;oldname:_row_alt0_valid1__row_alt0_port2
	bit<8> _row_alt0_valid1__row_alt0_po4
	;oldname:_row_alt1_valid3__row_alt1_port4
	bit<8> _row_alt1_valid3__row_alt1_po5
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
	jmpeq P_GETH1 h.h1._a0 0x0
	extract h.u.h2
	jmp P_ACCEPT
	P_GETH1 :	extract h.u.h1
	P_ACCEPT :	jmpnv LABEL_END h.u.h2
	invalidate h.u.h2
	LABEL_END :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.h1
	emit h.u.h1
	emit h.u.h2
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


