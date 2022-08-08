
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
	bit<8> Ingress_hasReturned
}
metadata instanceof Meta

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x0
	extract h.eth_hdr
	mov m.Ingress_hasReturned 0
	jmpeq LABEL_FALSE h.eth_hdr.dst_addr 0x0
	jmp LABEL_END
	LABEL_FALSE :	mov m.Ingress_hasReturned 1
	LABEL_END :	jmpneq LABEL_FALSE_0 m.Ingress_hasReturned 0x1
	jmp LABEL_END_0
	LABEL_FALSE_0 :	mov m.Ingress_tmp 0x1
	mov h.eth_hdr.src_addr m.Ingress_tmp
	LABEL_END_0 :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.eth_hdr
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


