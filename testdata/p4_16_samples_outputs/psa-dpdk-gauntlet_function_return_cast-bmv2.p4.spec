
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
}
metadata instanceof Meta

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	mov h.eth_hdr.eth_type 0xff
	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


