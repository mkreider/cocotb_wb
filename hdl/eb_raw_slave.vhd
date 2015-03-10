--! @file eb_slave.vhd
--! @brief Top file for EtherBone core
--!
--! Copyright (C) 2011-2012 GSI Helmholtz Centre for Heavy Ion Research GmbH 
--!
--! Important details about its implementation
--! should go in these comments.
--!
--! @author Mathias Kreider <m.kreider@gsi.de>
--! @author Wesley W. Terpstra <w.terpstra@gsi.de>
--!
--------------------------------------------------------------------------------
--! This library is free software; you can redistribute it and/or
--! modify it under the terms of the GNU Lesser General Public
--! License as published by the Free Software Foundation; either
--! version 3 of the License, or (at your option) any later version.
--!
--! This library is distributed in the hope that it will be useful,
--! but WITHOUT ANY WARRANTY; without even the implied warranty of
--! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--! Lesser General Public License for more details.
--!  
--! You should have received a copy of the GNU Lesser General Public
--! License along with this library. If not, see <http://www.gnu.org/licenses/>.
---------------------------------------------------------------------------------

--! Standard library
library IEEE;
--! Standard packages    
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.etherbone_pkg.all;
use work.eb_hdr_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.eb_internals_pkg.all;

entity eb_raw_slave is
  generic(
    g_sdb_address    : std_logic_vector(63 downto 0);
    g_timeout_cycles : natural;
    g_bus_width      : natural);
  port(
    clk_i       : in std_logic;
    nRst_i      : in std_logic;
    snk_i       : in  t_wishbone_slave_in;
    snk_o       : out t_wishbone_slave_out;
    src_o       : out t_wishbone_master_out;
    src_i       : in  t_wishbone_master_in;
    cfg_slave_o : out t_wishbone_slave_out;
    cfg_slave_i : in  t_wishbone_slave_in;
    master_o    : out t_wishbone_master_out;
    master_i    : in  t_wishbone_master_in);
end eb_raw_slave;

architecture rtl of eb_raw_slave is
  signal s_rx2fsm : t_wishbone_master_out;
  signal s_fsm2rx : t_wishbone_master_in;
  signal s_tx2fsm : t_wishbone_master_in;
  signal s_fsm2tx : t_wishbone_master_out;
begin

  RX : eb_stream_widen
    generic map(
      g_slave_width  => g_bus_width,
      g_master_width => 32)
    port map(
      clk_i    => clk_i,
      rst_n_i  => nRst_i,
      slave_i  => snk_i,
      slave_o  => snk_o,
      master_i => s_fsm2rx,
      master_o => s_rx2fsm);
  
  TX : eb_stream_narrow
    generic map(
      g_slave_width  => 32,
      g_master_width => g_bus_width)
    port map(
      clk_i    => clk_i,
      rst_n_i  => nRst_i,
      slave_i  => s_fsm2tx,
      slave_o  => s_tx2fsm,
      master_i => src_i,
      master_o => src_o);
  
  EB : eb_slave_top
    generic map(
      g_sdb_address    => g_sdb_address(31 downto 0),
      g_timeout_cycles => g_timeout_cycles)
    port map(
      clk_i        => clk_i,
      nRst_i       => nRst_i,
      EB_RX_i      => s_rx2fsm,
      EB_RX_o      => s_fsm2rx,
      EB_TX_i      => s_tx2fsm,
      EB_TX_o      => s_fsm2tx,
      skip_stb_o   => open,
      skip_stall_i => '0',
      WB_config_i  => cfg_slave_i,
      WB_config_o  => cfg_slave_o,
      WB_master_i  => master_i,
      WB_master_o  => master_o,
      my_mac_o     => open,
      my_ip_o      => open,
      my_port_o    => open);

end rtl;
