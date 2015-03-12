

# Modelsim is 32-bit only
VPI_LIB := vpi
ARCH:=i686
ROOTPATH = $(PATH)
SIM_ROOT = $(PWD)/../../..
LIB_DIR = $(SIM_ROOT)/build/libs/i686:/opt/pym32/lib

#GUI ?= ""
#TOPLEVEL ?= avalon_wrapper
#MODULE = test_av2wb
ifeq ($(GUI),1)
SIM_CMD = vsim -gui
VSIM_ARGS += -onfinish stop
else
SIM_CMD = vsim -c
VSIM_ARGS += -onfinish exit
endif

VSIM_ARGS += -pli libvpi.so

runsim.do : 
	echo "printenv" >> $@
	echo "vlib work" > $@
	echo "vsim $(VSIM_ARGS) $(TOPLEVEL)" >> $@

ifneq ($(GUI),1)
	echo "run -all" >> $@
	echo "quit" >> $@
endif

.PHONY: simrun
simrun: sim results.xml
	-@rm -f results.xml
	
clean::
	rm runsim.do
	rm results.xml   

results.xml: runsim.do
	sudo NEWPATH=$(ROOTPATH) -- bash -c 'export PATH=$(PATH):$(NEWPATH); export LD_LIBRARY_PATH=$(LIB_DIR):$(LD_LIBRARY_PATH); SIM_ROOT=$(SIM_ROOT) MODULE=$(MODULE) TESTCASE=$(TESTCASE) TOPLEVEL=$(TOPLEVEL) PYTHONPATH=$(LIB_DIR):$(SIM_ROOT):$(PWD):$(PYTHONPATH) $(SIM_CMD) -do runsim.do 2>&1 | tee sim.log'


