library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.apb_tb_pkg.all;


entity wmask_apb_tb is
end wmask_apb_tb;


architecture tb of wmask_apb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal apb_in  : t_apb_master_in;
  signal apb_out : t_apb_master_out;

  signal reg_rw       : std_logic_vector(31 downto 0);
  signal wire_rw_in   : std_logic_vector(31 downto 0);
  signal wire_rw_out  : std_logic_vector(31 downto 0);
  signal wire_rw_mask : std_logic_vector(31 downto 0);

  signal end_of_test : boolean := False;
begin
  --  Clock and reset
  clk_rst : process is
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;

    if end_of_test then
      wait;
    end if;
  end process clk_rst;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.wmask_apb
    port map (
      pclk            => clk,
      presetn         => rst_n,
      paddr           => apb_out.paddr(5 downto 2),
      psel            => apb_out.psel,
      pwrite          => apb_out.pwrite,
      penable         => apb_out.penable,
      pready          => apb_in.pready,
      pwdata          => apb_out.pwdata,
      pstrb           => apb_out.pstrb,
      prdata          => apb_in.prdata,
      pslverr         => apb_in.pslverr,

      reg_rw_o        => reg_rw,
      reg_ro_i        => (others => '0'),
      reg_wo_o        => open,
      wire_rw_i       => wire_rw_in,
      wire_rw_o       => wire_rw_out,
      wire_rw_wmask_o => wire_rw_mask,
      wire_ro_i       => (others => '0'),
      wire_wo_o       => open,
      wire_wo_wmask_o => open,
      ram1_adr_i      => (others => '0'),
      ram1_row1_rd_i  => '0',
      ram1_row1_dat_o => open
    );

  wire_rw_in <= wire_rw_out;

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    apb_init(apb_out);

    -- Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    -- Register
    -- Testing regular register read
    report "Testing regular register read" severity note;
    apb_read(clk, apb_out, apb_in, x"0000_0000", v);
    assert reg_rw = x"0000_0000" severity error;
    assert v = x"0000_0000" severity error;

    -- Testing regular register write
    report "Testing regular register write" severity note;
    apb_write(clk, apb_out, apb_in, x"0000_0000", x"1234_5678", "1111");
    wait until rising_edge(clk);
    assert reg_rw = x"1234_5678" severity error;
    apb_read(clk, apb_out, apb_in, x"0000_0000", v);
    assert v = x"1234_5678" severity error;

    --  Testing register write with mask
    report "Testing register write with mask" severity note;
    apb_write(clk, apb_out, apb_in, x"0000_0000", x"9abc_def0", "1010");
    wait until rising_edge(clk);
    assert reg_rw = x"9a34_de78" severity error;
    apb_read(clk, apb_out, apb_in, x"0000_0000", v);
    assert v = x"9a34_de78" severity error;

    -- Wire
    -- Testing regular write write
    report "Testing regular wire write" severity note;
    apb_write(clk, apb_out, apb_in, x"0000_0008", x"3456_789a", "1111");
    wait until rising_edge(clk);
    assert wire_rw_out = x"3456_789a" severity error;
    assert wire_rw_mask = x"ffff_ffff" severity error;

    report "Testing wire write with mask" severity note;
    apb_write(clk, apb_out, apb_in, x"0000_0008", x"bcde_f012", "0101");
    wait until rising_edge(clk);
    assert wire_rw_out = x"bcde_f012" severity error;
    assert wire_rw_mask = x"00ff_00ff" severity error;

    -- Memory
    -- Testing regular memory write
    report "Testing regular memory write" severity note;
    apb_write(clk, apb_out, apb_in, x"0010_0000", x"1234_5678", "1111");
    wait until rising_edge(clk);
    assert reg_rw = x"1234_5678" severity error;
    apb_read(clk, apb_out, apb_in, x"0010_0000", v);
    assert v = x"1234_5678" severity error;

    -- Testing memory write with mask
    report "Testing memory write with mask" severity note;
    apb_write(clk, apb_out, apb_in, x"0010_0000", x"9abc_def0", "1010");
    wait until rising_edge(clk);
    assert reg_rw = x"9a34_de78" severity error;
    apb_read(clk, apb_out, apb_in, x"0010_0000", v);
    assert v = x"9a34_de78" severity error;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    report "End of test" severity note;
    end_of_test <= true;
  end process main;

  watchdog : process is
  begin
    wait until end_of_test for 5 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process watchdog;

end tb;
