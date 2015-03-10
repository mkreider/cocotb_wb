''' Copyright (c) 2013 Potential Ventures Ltd
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Potential Ventures Ltd,
      SolarFlare Communications Inc nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL POTENTIAL VENTURES LTD BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. '''
import time
import random
import logging
import sys
import fcntl
import os
import struct
import subprocess

import cocotb

from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from cocotb.drivers.avalon import AvalonSTPkts as AvalonSTDriver
from cocotb.monitors.avalon import AvalonSTPkts as AvalonSTMonitor


def create_tun(name="tun0", ip="192.168.255.1"):
    cocotb.log.info("Attempting to create interface %s (%s)" % (name, ip))
    TUNSETIFF = 0x400454ca
    TUNSETOWNER = TUNSETIFF + 2
    IFF_TUN = 0x0001
    IFF_NO_PI = 0x1000
    tun = open('/dev/net/tun', 'r+b')
    ifr = struct.pack('16sH', name, IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    fcntl.ioctl(tun, TUNSETOWNER, 1000)
    subprocess.check_call('ifconfig tun0 %s up pointopoint 192.168.255.2 up' % ip, shell=True)

    return tun


@cocotb.test()
def test_av2wb(dut):
    """Example of a test using TUN/TAP over WB.

    Creates an interface (192.168.255.1) and any packets received are sent
    into the DUT.  The response output by the DUT is then sent back out on
    this interface.

    Note to create the TUN interface this test must be run as root or the user
    must have CAP_NET_ADMIN capability.
    """

    cocotb.fork(Clock(dut.clk, 5000).start())
    cocotb.fork(Clock(dut.clk2, 5000).start())
    
    
    stream_in  = AvalonSTDriver(dut, "stream_in", dut.clk2)
    stream_out = AvalonSTMonitor(dut, "stream_out", dut.clk2)

    # Enable verbose logging so we can see what's going on
    stream_in.log.setLevel(logging.DEBUG)
    stream_out.log.setLevel(logging.DEBUG)


    # Reset the DUT
    dut.log.debug("Resetting DUT")
    dut.reset_n <= 0
    dut.reset_n2 <= 0
    dut.mac_src <= 0xD15EA5EDBEEF
    dut.mac_dst <= 0xffffffffffff
    
    stream_in.bus.valid <= 0
    yield Timer(20000)
    yield RisingEdge(dut.clk)
    dut.reset_n <= 1
    yield RisingEdge(dut.clk2)
    dut.reset_n2 <= 1
    dut.stream_out_ready <= 1
    dut.log.debug("Out of reset")


    # Create our interface (destroyed at the end of the test)
    tun = create_tun()
    fd = tun.fileno()
    print os.fstat(fd)
    print os.fstat(tun.fileno())
    
    # Kick off a ping...
    #subprocess.check_call('ping -c 5 192.168.255.2 &', shell=True)
    subprocess.check_call('sudo tcpdump -x -i tun0 > ../dump.txt &', shell=True)
    subprocess.check_call('ifconfig', shell=True)
    #subprocess.check_call('eb-read -a 32 -d 32 -b -r 0 -s -p udp/192.168.255.2 0x0/4 &', shell=True)
    subprocess.check_call('eb-ls udp/192.168.255.2 &', shell=True)
    
    
    # Respond to 5 pings, then quit
    for i in xrange(5):

        cocotb.log.info("Waiting for packets on tun interface")
        packet = os.read(fd, 2048)
        cocotb.log.info("Received a packet!")


        stream_in.append(packet)
        result = yield stream_out.wait_for_recv()
        os.write(fd, str(result))
        cocotb.log.info("Rtl replied!")
        
