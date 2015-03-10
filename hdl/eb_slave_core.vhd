library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.etherbone_pkg.all;

entity eb_slave_core is
  generic(
    g_sdb_address    : std_logic_vector(63 downto 0);
    g_timeout_cycles : natural;
    g_mtu            : natural);
  port(
    clk_i       : in  std_logic;
    nRst_i      : in  std_logic;
    snk_i       : in  t_wrf_sink_in;
    snk_o       : out t_wrf_sink_out;
    src_o       : out t_wrf_source_out;
    src_i       : in  t_wrf_source_in;
    cfg_slave_o : out t_wishbone_slave_out;
    cfg_slave_i : in  t_wishbone_slave_in;
    master_o    : out t_wishbone_master_out;
    master_i    : in  t_wishbone_master_in);
end eb_slave_core;

architecture rtl of eb_slave_core is
begin
  
  assert (false)
  report "eb_slave_core is obsolete and will be removed. switch to eb_ethernet_slave."
  severity warning;

  eb : eb_ethernet_slave
    generic map(
      g_sdb_address    => g_sdb_address,
      g_timeout_cycles => g_timeout_cycles,
      g_mtu            => g_mtu)
    port map(
      clk_i       => clk_i,
      nRst_i      => nRst_i,
      snk_i       => snk_i,
      snk_o       => snk_o,
      src_o       => src_o,
      src_i       => src_i,
      cfg_slave_o => cfg_slave_o,
      cfg_slave_i => cfg_slave_i,
      master_o    => master_o,
      master_i    => master_i);

end rtl;
