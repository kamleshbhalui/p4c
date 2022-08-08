
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
	bit<48> Ingress_tmp
	bit<48> Ingress_tmp_0
}
metadata instanceof Meta

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	jmplt LABEL_TRUE h.eth_hdr.src_addr 0xa
	jmp LABEL_END
	LABEL_TRUE :	mov m.Ingress_tmp h.eth_hdr.dst_addr
	shl m.Ingress_tmp 0x2
	mov m.Ingress_tmp_0 m.Ingress_tmp
	and m.Ingress_tmp_0 0xffff
	mov h.eth_hdr.eth_type m.Ingress_tmp_0
	LABEL_END :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


