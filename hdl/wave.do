onerror {resume}
quietly WaveActivateNextPane {} 0
add wave sim:/avalon_wrapper/u1/*
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/clk_sys_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/rst_sys_n_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/clk_ref_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/rst_ref_n_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/data_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/empty_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/valid_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/sop_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/eop_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/ready_in_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/data_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/empty_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/valid_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/sop_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/eop_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/ready_out_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/r_cwb_snk_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_cwb_snk_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_cwb_src_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_cwb_src_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fab2widen
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_widen2fab
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fab2narrow
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_narrow2fab
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/r_cyc_out
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/r_cyc_in
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/r_sop
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/r_cyc_done
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_src_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_src_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_snk_i
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_snk_o
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/cbar_slaveport_in
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/cbar_slaveport_out
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/cbar_masterport_in
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/cbar_masterport_out
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_push
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_pop
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_empty
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_full
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_almost_empty
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_d
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_q
add wave -noupdate -radix hexadecimal /avalon_wrapper/u1/s_fifo_out_count
add wave -noupdate /avalon_wrapper/u1/U_ebs/rx/r_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ns} {5945 ns}
