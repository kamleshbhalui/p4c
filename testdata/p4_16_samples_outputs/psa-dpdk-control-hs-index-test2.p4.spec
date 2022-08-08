
struct ethernet_t {
	bit<48> dst_addr
	bit<48> src_addr
	bit<16> eth_type
}

struct h_index {
	bit<32> index
}

struct h_stack {
	bit<32> a
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
header h_0 instanceof h_stack
header h_1 instanceof h_stack
header h_2 instanceof h_stack

header i instanceof h_index

struct Meta {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<32> Ingress_tmp
	bit<32> Ingress_tmp_0
	bit<32> Ingress_tmp_1
}
metadata instanceof Meta

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	extract h.h_0
	extract h.h_1
	extract h.h_2
	extract h.i
	mov m.Ingress_tmp_1 h.i.index
	add m.Ingress_tmp_1 0x1
	jmpneq LABEL_FALSE m.Ingress_tmp_1 0x0
	mov h.h_0.a 0x1
	jmp LABEL_END
	LABEL_FALSE :	mov m.Ingress_tmp_0 h.i.index
	add m.Ingress_tmp_0 0x1
	jmpneq LABEL_FALSE_0 m.Ingress_tmp_0 0x1
	mov h.h_1.a 0x1
	jmp LABEL_END
	LABEL_FALSE_0 :	mov m.Ingress_tmp h.i.index
	add m.Ingress_tmp 0x1
	jmpneq LABEL_END m.Ingress_tmp 0x2
	mov h.h_2.a 0x1
	LABEL_END :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	emit h.h_0
	emit h.h_1
	emit h.h_2
	emit h.i
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


