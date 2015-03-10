PWD=$(shell pwd)
COCOTB=$(PWD)/../../..

SIM=modelsim
GPI_IMPL=vpi
GPI_EXTRA=vhpi
#GUI=1

TOPLEVEL_LANG=verilog
VERILOG_SOURCES = $(PWD)/../hdl/avalon_wrapper.v
TOPLEVEL=avalon_wrapper
VHDL_SOURCES = $(PWD)/../hdl/cocotb_netw.vhd
VHDL_SOURCES += $(PWD)/../hdl/eb_hdr_pkg.vhd
VHDL_SOURCES += $(PWD)/../hdl/eb_internals_pkg.vhd
VHDL_SOURCES += $(PWD)/../hdl/eb_stream_narrow.vhd
VHDL_SOURCES += $(PWD)/../hdl/eb_stream_widen.vhd
VHDL_SOURCES += $(PWD)/../hdl/etherbone_pkg.vhd
VHDL_SOURCES += $(PWD)/../hdl/genram_pkg.vhd
VHDL_SOURCES += $(PWD)/../hdl/wb_slave_adapter.vhd
VHDL_SOURCES += $(PWD)/../hdl/wishbone_pkg.vhd
VHDL_SOURCES += $(PWD)/../hdl/wr_fabric_pkg.vhd

MODULE=test_av2wb
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
