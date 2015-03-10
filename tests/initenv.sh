#!/bin/bash

NEWPATH="/opt/pym32/bin:/opt/hdl/modeltech:/opt/hdl/modeltech/linux:/opt/lm32:/opt/quartus_13_1/quartus:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/hdl/modeltech/linux"
echo $NEWPATH
sudo NEWPATH=$NEWPATH -- bash -c 'export PATH=$PATH:$NEWPATH; export LD_LIBRARY_PATH=/opt/pym32/lib; make SIM=modelsim'
