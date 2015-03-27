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

''' extremely modified ping example - Mathias Kreider March 2015 '''

import time
import random
import logging
import sys
import fcntl
import os
import struct
import subprocess
import thread

import cocotb
from cocotb.decorators import coroutine
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from cocotb.drivers.avalon import AvalonSTPkts as AvalonSTDriver
from cocotb.monitors.avalon import AvalonSTPkts as AvalonSTMonitor


@cocotb.coroutine
def sender_coro(dut, fd, av):
    """
    Polls the socket for new data each clock cycle and sends it into the DUT
    """
    while True:
        yield RisingEdge(dut.clk2)
        try:
            data = os.read(fd, 2048)
            av.append(str(data))
        except os.error :
            pass    
        
class packet_out():
   def __init__ (self, fd):
      self.fd = fd
      
   def recv(self, result):
      os.write(self.fd, str(result))    

def create_tun(name="tun0", ip="192.168.0.101"):
    cocotb.log.info("Attempting to create interface %s (%s)" % (name, ip))
    TUNSETIFF = 0x400454ca
    TUNSETOWNER = TUNSETIFF + 2
    IFF_TUN = 0x0001
    IFF_NO_PI = 0x1000
    tun = open('/dev/net/tun', 'r+b')
    ifr = struct.pack('16sH', name, IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    fcntl.ioctl(tun, TUNSETOWNER, 1000)
    
    subprocess.check_call('ifconfig tun0 %s netmask 255.255.255.254 up' % ip, shell=True)
    return tun


def input_thread(L):
    raw_input()
    L.append(None)
    
  



@cocotb.test()
def test_av2wb(dut):
    """Example of a test using TUN/TAP over WB."""
    cocotb.fork(Clock(dut.clk, 5000).start())
    cocotb.fork(Clock(dut.clk2, 5000).start())
    
    tun = create_tun()
    fd = tun.fileno()
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
    pktOut = packet_out(fd)
    stream_in  = AvalonSTDriver(dut, "stream_in", dut.clk2)
    stream_out = AvalonSTMonitor(entity=dut, name="stream_out", clock=dut.clk2, callback=pktOut.recv)
    cocotb.fork(sender_coro(dut, os.dup(fd), stream_in))
    
    # Enable verbose logging so we can see what's going on
    stream_in.log.setLevel(logging.INFO)
    stream_out.log.setLevel(logging.INFO)
    
    # Reset the DUT
    dut.log.debug("Resetting DUT")
    dut.reset_n <= 0
    dut.reset_n2 <= 0
    dut.mac_src <= 0xD15EA5EDBEEF # doesn't matter for tun, use tap in the future
    dut.mac_dst <= 0xffffffffffff
    
    stream_in.bus.valid <= 0
    yield Timer(20000)
    yield RisingEdge(dut.clk)
    dut.reset_n <= 1
    yield RisingEdge(dut.clk2)
    dut.reset_n2 <= 1
    dut.stream_out_ready <= 1
    dut.log.debug("Out of reset")
        
    #p = subprocess.Popen(["eb-ls", "udp/192.168.0.100"])

    L = []
    thread.start_new_thread(input_thread, (L,))
    print "Press Any key to close"
    while True:
       if L: 
          print L
          break
       yield RisingEdge(dut.clk2)

    print "DONE *****"
       
   
    
    
        
