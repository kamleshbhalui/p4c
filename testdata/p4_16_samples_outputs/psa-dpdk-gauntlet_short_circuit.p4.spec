
struct ethernet_t {
	bit<48> dst_addr
	bit<48> src_addr
	bit<16> eth_type
}

struct H {
	bit<8> a
	bit<8> b
	bit<8> c
	bit<8> d
}

struct B {
	bit<8> a
	bit<8> b
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
header h instanceof H
header b instanceof B

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<8> Ingress_tmp
	bit<8> Ingress_val
}
metadata instanceof Meta

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	extract h.h
	extract h.b
	mov h.b.b m.Ingress_val
	jmpeq LABEL_FALSE 0x1 m.Ingress_val
	mov m.Ingress_tmp 0x1
	jmp LABEL_END
	LABEL_FALSE :	mov m.Ingress_tmp 0x2
	LABEL_END :	mov h.b.a m.Ingress_tmp
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	emit h.h
	emit h.b
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


