###################################
## enter your project details here
testmodule  = "test_av2wb"
testcase    = ""
top_module  = "avalon_wrapper"
##################################

target         = "altera"
action         = "simulation"
sim_tool       = "modelsim"
vlog_opt       = "-timescale 1ns/100ps -mfcu +acc=rmb -sv"

sim_pre_cmd    = "$(eval TOPLEVEL = %s)\n\t$(eval MODULE = %s)\n\t$(eval TESTCASE = %s)\n" % (top_module, testmodule, testcase)
incl_makefiles = ["build.mk"]

modules = {
  "local" : [ 
    "../hdl"  
  ]
}


