library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.eb_internals_pkg.all;
use work.eb_hdr_pkg.all;
use work.etherbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.genram_pkg.all;

entity cocotb_netw is
	port (
		clk_sys_i : in std_logic;
		rst_sys_n_i : in std_logic;
		
		clk_ref_i   : in std_logic;
		rst_ref_n_i : in std_logic;
		
		mac_src_i : in std_logic_vector(6*8-1 downto 0);
		mac_dst_i : in std_logic_vector(6*8-1 downto 0);
		
		data_i   : in std_logic_vector(31 downto 0);
      empty_i  : in std_logic_vector(1 downto 0); 
      valid_i  : in std_logic;
      sop_i    : in std_logic; 
      eop_i    : in std_logic;
      ready_in_o  : out std_logic;
      
      data_o   : out std_logic_vector(31 downto 0);
      empty_o  : out std_logic_vector(1 downto 0); 
      valid_o  : out std_logic;
      sop_o    : out std_logic; 
      eop_o    : out std_logic;
      ready_out_i  : in std_logic
      
		);
end entity;

architecture rtl of cocotb_netw is

   
   signal r_cwb_snk_i  : t_wishbone_slave_in;
   signal s_cwb_snk_o  : t_wishbone_slave_out;
   signal s_cwb_src_i  : t_wishbone_master_in;
   signal s_cwb_src_o  : t_wishbone_master_out;
   
   signal s_tx2widen   : t_wishbone_master_in;
   signal s_widen2tx   : t_wishbone_master_out;
   signal s_rx2narrow  : t_wishbone_slave_in; 
   signal s_narrow2rx  : t_wishbone_slave_out;
   
   signal s_fab2widen   : t_wishbone_master_out;
   signal s_widen2fab   : t_wishbone_master_in;
   signal s_fab2narrow  : t_wishbone_slave_out; 
   signal s_narrow2fab  : t_wishbone_slave_in;
   
   signal r_cyc_in_done : std_logic;
   signal r_cyc_out     : std_logic;
   signal r_sop         : std_logic;
   signal r_cyc_done    : std_logic;
   signal r_narrow2fab_cyc : std_logic;
   
   
   
   --ebs
   signal s_src_i         : t_wrf_source_in;
   signal s_src_o         : t_wrf_source_out;
   signal s_snk_i         : t_wrf_sink_in;
   signal s_snk_o         : t_wrf_sink_out;
   signal s_cfg_slave_o : t_wishbone_slave_out;
   signal s_cfg_slave_i : t_wishbone_slave_in;
   signal s_wb_master_o : t_wishbone_master_out;
   signal s_wb_master_i : t_wishbone_master_in;
   
   --cb
   constant c_masters : natural := 1;
   constant c_slaves  : natural := 2;
   
   constant c_cbs_ram : natural := 0;
   constant c_cbs_cfg_space : natural := 1;
   
   constant c_cbm_eb : natural := 0;
   
   
   constant c_ram_size : natural := 512;
   
   signal cbar_slaveport_in   : t_wishbone_slave_in_array (c_masters-1 downto 0); 
   signal cbar_slaveport_out  : t_wishbone_slave_out_array(c_masters-1 downto 0);
   signal cbar_masterport_in  : t_wishbone_master_in_array (c_slaves-1 downto 0); 
   signal cbar_masterport_out : t_wishbone_master_out_array(c_slaves-1 downto 0);
      constant c_tmp_layout : t_sdb_record_array(c_slaves-1 downto 0) :=
   (c_cbs_ram                    => f_sdb_auto_device(f_xwb_dpram(c_ram_size),   true),
    c_cbs_cfg_space              => f_sdb_auto_device(c_etherbone_sdb,   true)
   );
   
   constant c_layout       : t_sdb_record_array(c_slaves-1 downto 0) := f_sdb_auto_layout(c_tmp_layout);
   constant c_sdb_address  : t_wishbone_address                      := f_sdb_auto_sdb(c_tmp_layout);  
   
   
   signal s_fifo_out_push : std_logic;
   signal s_fifo_out_pop : std_logic;
   signal s_fifo_out_empty : std_logic;
   signal s_fifo_out_full : std_logic;
   signal s_fifo_out_almost_empty : std_logic;   
   signal s_fifo_out_d : std_logic_vector(32 +4-1 downto 0);
   signal s_fifo_out_q : std_logic_vector(32 +4-1 downto 0);
   signal s_fifo_out_count : std_logic_vector(f_log2_size(512)-1 downto 0);
   
   signal s_fifo_in_push : std_logic;
   signal s_fifo_in_pop : std_logic;
   signal s_fifo_in_empty : std_logic;
   signal s_fifo_in_full : std_logic;
   signal s_fifo_in_almost_empty : std_logic;   
   signal s_fifo_in_d : std_logic_vector(32 +2-1 downto 0);
   signal s_fifo_in_q : std_logic_vector(32 +2-1 downto 0);
   signal s_fifo_in_count : std_logic_vector(f_log2_size(512)-1 downto 0);
   
   signal r_hdr_cnt_out : std_logic_vector(3 downto 0);
   signal r_hdr_cnt_in : std_logic_vector(3 downto 0);
   signal r_hdr_ackcnt_in : std_logic_vector(3 downto 0);
   signal r_hdr_in : std_logic_vector(14*8-1 downto 0);
begin

   fifo_in : generic_sync_fifo
    generic map(
      g_data_width             => 32 + 2,
      g_size                   => 512,
      g_show_ahead             => true,
      g_with_empty             => true,
      g_with_full              => true,
      g_with_almost_full       => false,
      g_with_almost_empty      => true,
      g_with_count        => true,
      g_almost_empty_threshold => 1)
    port map (
      clk_i   => clk_sys_i,
      rst_n_i => rst_sys_n_i,
      full_o  => s_fifo_in_full,
      we_i    => s_fifo_in_push,
      d_i     => s_fifo_in_d,
      empty_o => s_fifo_in_empty,
      almost_empty_o => open,
      rd_i    => s_fifo_in_pop,
      q_o     => s_fifo_in_q,
      count_o => s_fifo_in_count); 

  
  s_fifo_in_push  <= valid_i;
  s_fifo_in_d     <= empty_i & data_i;
  s_fifo_in_pop   <= r_cwb_snk_i.cyc and r_cwb_snk_i.stb and not s_cwb_snk_o.stall;
  ready_in_o      <= not s_fifo_in_full;
  r_cwb_snk_i.cyc <= not s_fifo_in_empty;
  r_cwb_snk_i.stb <= not s_fifo_in_empty;
  r_cwb_snk_i.dat <= s_fifo_in_q(31 downto 0);
  r_cwb_snk_i.adr <= (others=>'0');
  r_cwb_snk_i.we  <= '1';           


  

   Mux_bs_i: with s_fifo_out_q(33 downto 32) select
   r_cwb_snk_i.sel <=   "0111" when "01",
                        "0011" when "10",
                        "0001" when "11",
                        "1111" when others;      
  
   



   narrow : eb_stream_narrow
   generic map(
      g_slave_width  => 32,
      g_master_width => 16)
   port map(
      clk_i    => clk_sys_i,
      rst_n_i  => rst_sys_n_i,
      slave_i  => r_cwb_snk_i, 
      slave_o  => s_cwb_snk_o,
      master_i => s_fab2narrow,
      master_o => s_narrow2fab);

   av2cwb : process(clk_sys_i)
      variable v_cnt : natural;
   begin
      if( rising_edge(clk_sys_i)) then
         if(rst_sys_n_i = '0') then
            r_cyc_in_done      <= '0';
         else
            r_narrow2fab_cyc <= s_narrow2fab.cyc;
            
            if((eop_i and valid_i) = '1') then
               r_cyc_in_done <= '1';  
            end if;
            r_cyc_in_done <= r_cyc_in_done and (r_narrow2fab_cyc and not s_narrow2fab.cyc);
         end if;
      end if;      
   end process;   
   


   
   Mux1: with empty_i select
  r_cwb_snk_i.sel <= "0111" when "01",
                     "0011" when "10",
                     "0001" when "11",
                     "1111" when others; 
   
   
      
   widen : eb_stream_widen
   generic map(
      g_slave_width  => 16,
      g_master_width => 32)
   port map(
      clk_i    => clk_sys_i,
      rst_n_i  => rst_sys_n_i,
      slave_i  => s_fab2widen, 
      slave_o  => s_widen2fab,
      master_i => s_cwb_src_i,
      master_o => s_cwb_src_o);   
  
    fifo_out : generic_sync_fifo
    generic map(
      g_data_width             => 32 + 4,
      g_size                   => 512,
      g_show_ahead             => true,
      g_with_empty             => true,
      g_with_full              => true,
      g_with_almost_full       => false,
      g_with_almost_empty      => true,
      g_with_count        => true,
      g_almost_empty_threshold => 1)
    port map (
      clk_i   => clk_sys_i,
      rst_n_i => rst_sys_n_i,
      full_o  => s_fifo_out_full,
      we_i    => s_fifo_out_push,
      d_i     => s_fifo_out_d,
      empty_o => s_fifo_out_empty,
      almost_empty_o => open,
      rd_i    => s_fifo_out_pop,
      q_o     => s_fifo_out_q,
      count_o => s_fifo_out_count); 
  
  
  cwb2av : process(clk_sys_i)
      variable v_sel : std_logic_vector(3 downto 0);
   begin
      if( rising_edge(clk_sys_i)) then
         if(rst_sys_n_i = '0') then
            r_cyc_done <= '0';
            r_cyc_out <= '0';
            r_sop <= '0'; 
         else
            r_cyc_out <= s_cwb_src_o.cyc;
            
            if(r_cyc_out and not s_cwb_src_o.cyc) ='1' then 
               r_cyc_done <= '1';
               r_sop      <= '1';
            end if;
            
            if(s_fifo_out_pop = '1') then 
               r_sop <= '0';
            end if; 
            
            if(s_fifo_out_empty = '1') then 
               r_cyc_done <= '0';
            end if;   
        end if;   
      end if;      
   end process;   

  s_fifo_out_almost_empty <= '1' when to_integer(unsigned(s_fifo_out_count)) = 1
                        else '0';
  s_fifo_out_push <= (s_cwb_src_o.cyc and s_cwb_src_o.stb and not s_cwb_src_i.stall);
  s_fifo_out_d    <= s_cwb_src_o.sel & s_cwb_src_o.dat;
  s_fifo_out_pop  <= not s_fifo_out_empty and ready_out_i and r_cyc_done;
  
  
  
  -- Mux this depending on eth hdr
  valid_o         <= not s_fifo_out_empty and r_cyc_done;
  sop_o           <= r_sop;   
  
  data_o          <= s_fifo_out_q(31 downto 0);
  eop_o           <= s_fifo_out_almost_empty and r_cyc_done;
  



Mux_bs_o: with s_fifo_out_q(35 downto 32) select
  empty_o         <= "01" when "0111",
                     "10" when "0011",
                     "11" when "0001",
                     "00" when others;      
  
   
   s_cwb_src_i.stall <= s_fifo_out_full;
	s_cwb_src_i.err   <= '0';
	s_cwb_src_i.ack   <= s_cwb_src_o.cyc and s_cwb_src_o.stb and not s_cwb_src_i.stall;
	s_cwb_src_i.dat   <= (others => '0');
	
	------------------------------------------------------------------------------------------
	--          System architecture to be simulated
	------------------------------------------------------------------------------------------
		-- convert to fabric IF
	
	-- snk / src from the eb slave perspective
	s_fab2widen.cyc      <= s_src_o.cyc;
	s_fab2widen.stb      <= s_src_o.stb and r_hdr_cnt_out(r_hdr_cnt_out'left);
	s_fab2widen.dat(15 downto 0) <= s_src_o.dat;
	s_fab2widen.adr      <= (others => '0');
	s_src_i.ack          <= s_widen2fab.ack or (s_src_o.cyc and s_src_o.stb and not s_widen2fab.stall and not r_hdr_cnt_out(r_hdr_cnt_out'left));
	s_src_i.err          <= s_widen2fab.err;
	s_src_i.stall        <= s_widen2fab.stall;
	
	fab2widen_hdr : process(clk_sys_i)
      variable v_sel : std_logic_vector(3 downto 0);
   begin
      if( rising_edge(clk_sys_i)) then
         if(rst_sys_n_i = '0') then
            r_hdr_cnt_out <= std_logic_vector(to_unsigned(6 , 4));
         else
            if(s_src_o.cyc = '0') then 
               r_hdr_cnt_out <= std_logic_vector(to_unsigned(6 , 4));   
            end if;
            
            if((s_src_o.cyc and not r_hdr_cnt_out(r_hdr_cnt_out'left)) = '1') then
               r_hdr_cnt_out <= std_logic_vector(unsigned(r_hdr_cnt_out) -1);     
            end if;
        end if;   
      end if;      
   end process;   

	s_snk_i.cyc          <= s_narrow2fab.cyc or not r_hdr_cnt_in(r_hdr_cnt_in'left);

	s_snk_i.adr          <= "00";
	
	mux_snk_stb_i: with r_hdr_ackcnt_in(r_hdr_ackcnt_in'left) select
	s_snk_i.stb         <= s_narrow2fab.stb when '1',
                          not r_hdr_cnt_in(r_hdr_cnt_in'left) when others; 
	
	mux_snk_dat_i: with r_hdr_ackcnt_in(r_hdr_ackcnt_in'left) select
	s_snk_i.dat        <= s_narrow2fab.dat(15 downto 0) when '1',
                         r_hdr_in(r_hdr_in'left downto r_hdr_in'length-16) when others; 
	
	mux_snk_ack_o: with r_hdr_ackcnt_in(r_hdr_ackcnt_in'left) select
	s_fab2narrow.ack         <= s_snk_o.ack when '1',
                                       '0' when others; 
	
	mux_snk_err_o: with r_hdr_ackcnt_in(r_hdr_ackcnt_in'left) select
	s_fab2narrow.err         <= s_snk_o.err when '1',
                                       '0' when others; 

	s_fab2narrow.stall   <= s_snk_o.stall or not r_hdr_ackcnt_in(r_hdr_ackcnt_in'left);
	
	narrow2fab_hdr : process(clk_sys_i)
      variable v_sel : std_logic_vector(3 downto 0);
   begin
      if( rising_edge(clk_sys_i)) then
         if(rst_sys_n_i = '0') then
            r_hdr_cnt_in <= (others => '1');
            r_hdr_ackcnt_in <= (others => '1'); 
         else
            if((sop_i and valid_i) = '1') then 
               r_hdr_cnt_in <= std_logic_vector(to_unsigned(6 , 4));
               r_hdr_ackcnt_in <= std_logic_vector(to_unsigned(6 , 4));      
               r_hdr_in <= mac_dst_i & mac_src_i & x"0800";
            end if;
            
            if((not r_hdr_cnt_in(r_hdr_cnt_in'left) and s_snk_i.cyc and s_snk_i.stb and not s_snk_o.stall) = '1') then
               r_hdr_cnt_in <= std_logic_vector(unsigned(r_hdr_cnt_in) -1);
               r_hdr_in     <= r_hdr_in(r_hdr_in'left - 16 downto 0) & x"0000";
            end if;
            if((not r_hdr_ackcnt_in(r_hdr_ackcnt_in'left) and s_snk_o.ack) = '1') then
               r_hdr_ackcnt_in <= std_logic_vector(unsigned(r_hdr_ackcnt_in) -1);
            end if;
        end if;   
      end if;      
   end process;
	
	
	
	
	
   CON : xwb_sdb_crossbar
   generic map(
      g_num_masters => c_masters,
      g_num_slaves  => c_slaves,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_layout,
      g_sdb_addr    => c_sdb_address)
   port map(
      clk_sys_i     => clk_sys_i,
      rst_n_i       => rst_sys_n_i,
      -- Master connections (INTERCON is a slave)
      slave_i       => cbar_slaveport_in,
      slave_o       => cbar_slaveport_out,
      -- Slave connections (INTERCON is a master)
      master_i      => cbar_masterport_in,
      master_o      => cbar_masterport_out);

 
   DPRAM : xwb_dpram
   generic map(
      g_size                  => c_ram_size,
      g_init_file             => "",
      g_must_have_init_file   => true,
      g_slave1_interface_mode => PIPELINED,
      g_slave2_interface_mode => PIPELINED,
      g_slave1_granularity    => BYTE,
      g_slave2_granularity    => BYTE)  
   port map(
      clk_sys_i   => clk_sys_i,
      rst_n_i     => rst_sys_n_i,
      slave1_i    => cbar_masterport_out(c_cbs_ram),
      slave1_o    => cbar_masterport_in(c_cbs_ram),
      slave2_i    => ('0', '0', (others => '0'), (others => '0'), '0', (others => '0')),
      slave2_o    => open);

	U_ebs : eb_ethernet_slave
     generic map(
       g_sdb_address => x"00000000" & c_sdb_address)
     port map(
       clk_i       => clk_sys_i,
       nRst_i      => rst_sys_n_i,
       snk_i       => s_snk_i,
       snk_o       => s_snk_o,
       src_o       => s_src_o,
       src_i       => s_src_i,
       cfg_slave_o => cbar_masterport_in(c_cbs_cfg_space),
       cfg_slave_i => cbar_masterport_out(c_cbs_cfg_space),
       master_o    => cbar_slaveport_in(c_cbm_eb),
       master_i    => cbar_slaveport_out(c_cbm_eb));

	


end architecture;
