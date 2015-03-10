module avalon_wrapper (
    input                                  clk,
    input                                  reset_n,

    input                                  clk2,
    input                                  reset_n2,

    input [31:0]                           stream_in_data,
    input [1:0]                            stream_in_empty,
    input                                  stream_in_valid,
    input                                  stream_in_startofpacket,
    input                                  stream_in_endofpacket,
    output                                 stream_in_ready,

    output [31:0]                          stream_out_data,
    output [1:0]                           stream_out_empty,
    output                                 stream_out_valid,
    output                                 stream_out_startofpacket,
    output                                 stream_out_endofpacket,
    input                                  stream_out_ready,
    
    input [47:0]                           mac_src,
	 input [47:0]                           mac_dst 
);



cocotb_netw u1         (.clk_ref_i(clk),
                        .rst_ref_n_i(reset_n),
                        .clk_sys_i(clk2),
                        .rst_sys_n_i(reset_n2),
                        
                        .mac_src_i(mac_src),
		                  .mac_dst_i(mac_dst),
                        
                        .data_i(stream_in_data),
                        .empty_i(stream_in_empty),
                        .valid_i(stream_in_valid),
                        .sop_i(stream_in_startofpacket),
                        .eop_i(stream_in_endofpacket),
                        .ready_in_o(stream_in_ready),
                        
                        .data_o(stream_out_data),
                        .empty_o(stream_out_empty),
                        .valid_o(stream_out_valid),
                        .sop_o(stream_out_startofpacket),
                        .eop_o(stream_out_endofpacket),
                        .ready_out_i(stream_out_ready));


endmodule
