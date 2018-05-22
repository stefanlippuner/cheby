library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_cregs_splitaddr.all;

entity RegCtrl_cregs_splitaddr is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMERdAddr            : in    std_logic_vector(19 downto 2);
    VMEWrAddr            : in    std_logic_vector(19 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    VMERdError           : out   std_logic;
    VMEWrError           : out   std_logic;
    test1_b15            : in    std_logic;
    test3                : out   std_logic_vector(63 downto 0);
    test5                : out   std_logic_vector(31 downto 0);
    test7_b31            : in    std_logic
  );
end RegCtrl_cregs_splitaddr;

architecture syn of RegCtrl_cregs_splitaddr is
  component CtrlRegN
    generic (
      N : integer := 16
    );
    port (
      Clk                  : in    std_logic;
      Rst                  : in    std_logic;
      CRegSel              : in    std_logic;
      WriteMem             : in    std_logic;
      VMEWrData            : in    std_logic_vector(N-1 downto 0);
      AutoClrMsk           : in    std_logic_vector(N-1 downto 0);
      CReg                 : out   std_logic_vector(N-1 downto 0);
      Preset               : in    std_logic_vector(N-1 downto 0)
    );
  end component;
  for all : CtrlRegN use entity CommonVisual.CtrlRegN(V1);
  signal Loc_VMERdMem                   : std_logic_vector(2 downto 0);
  signal Loc_VMEWrMem                   : std_logic_vector(1 downto 0);
  signal CRegRdData                     : std_logic_vector(31 downto 0);
  signal CRegRdOK                       : std_logic;
  signal CRegWrOK                       : std_logic;
  signal Loc_CRegRdData                 : std_logic_vector(31 downto 0);
  signal Loc_CRegRdOK                   : std_logic;
  signal Loc_CRegWrOK                   : std_logic;
  signal RegRdDone                      : std_logic;
  signal RegWrDone                      : std_logic;
  signal RegRdData                      : std_logic_vector(31 downto 0);
  signal RegRdOK                        : std_logic;
  signal Loc_RegRdData                  : std_logic_vector(31 downto 0);
  signal Loc_RegRdOK                    : std_logic;
  signal MemRdData                      : std_logic_vector(31 downto 0);
  signal MemRdDone                      : std_logic;
  signal MemWrDone                      : std_logic;
  signal Loc_MemRdData                  : std_logic_vector(31 downto 0);
  signal Loc_MemRdDone                  : std_logic;
  signal Loc_MemWrDone                  : std_logic;
  signal RdData                         : std_logic_vector(31 downto 0);
  signal RdDone                         : std_logic;
  signal WrDone                         : std_logic;
  signal RegRdError                     : std_logic;
  signal RegWrError                     : std_logic;
  signal MemRdError                     : std_logic;
  signal MemWrError                     : std_logic;
  signal Loc_MemRdError                 : std_logic;
  signal Loc_MemWrError                 : std_logic;
  signal RdError                        : std_logic;
  signal WrError                        : std_logic;
  signal Loc_test1                      : std_logic_vector(31 downto 0);
  signal Loc_test3                      : std_logic_vector(63 downto 0);
  signal WrSel_test3_1                  : std_logic;
  signal WrSel_test3_0                  : std_logic;
  signal Loc_test5                      : std_logic_vector(31 downto 0);
  signal WrSel_test5                    : std_logic;
  signal Loc_test7                      : std_logic_vector(31 downto 0);

begin
  Reg_test3_1: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_1,
      AutoClrMsk           => C_ACM_cregs_splitaddr_test3_1,
      Preset               => C_PSM_cregs_splitaddr_test3_1,
      CReg                 => Loc_test3(63 downto 32)
    );
  
  Reg_test3_0: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_0,
      AutoClrMsk           => C_ACM_cregs_splitaddr_test3_0,
      Preset               => C_PSM_cregs_splitaddr_test3_0,
      CReg                 => Loc_test3(31 downto 0)
    );
  
  Reg_test5: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5,
      AutoClrMsk           => C_ACM_cregs_splitaddr_test5,
      Preset               => C_PSM_cregs_splitaddr_test5,
      CReg                 => Loc_test5(31 downto 0)
    );
  
  Loc_test1(31 downto 16) <= C_PSM_cregs_splitaddr_test1(31 downto 16);
  Loc_test1(15) <= test1_b15;
  Loc_test1(14 downto 0) <= C_PSM_cregs_splitaddr_test1(14 downto 0);
  test3 <= Loc_test3;
  test5 <= Loc_test5;
  Loc_test7(31) <= test7_b31;
  Loc_test7(30 downto 0) <= C_PSM_cregs_splitaddr_test7(30 downto 0);

  WrSelDec: process (VMEWrAddr) begin
    WrSel_test3_1 <= '0';
    WrSel_test3_0 <= '0';
    WrSel_test5 <= '0';
    case VMEWrAddr(19 downto 2) is
    when C_Reg_cregs_splitaddr_test3_1 => 
      WrSel_test3_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_splitaddr_test3_0 => 
      WrSel_test3_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_splitaddr_test5 => 
      WrSel_test5 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMERdAddr, Loc_test3, Loc_test5) begin
    case VMERdAddr(19 downto 2) is
    when C_Reg_cregs_splitaddr_test3_1 => 
      Loc_CRegRdData <= Loc_test3(63 downto 32);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_splitaddr_test3_0 => 
      Loc_CRegRdData <= Loc_test3(31 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_splitaddr_test5 => 
      Loc_CRegRdData <= Loc_test5(31 downto 0);
      Loc_CRegRdOK <= '1';
    when others =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    end case;
  end process CRegRdMux;

  CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      CRegRdData <= Loc_CRegRdData;
      CRegRdOK <= Loc_CRegRdOK;
      CRegWrOK <= Loc_CRegWrOK;
    end if;
  end process CRegRdMux_DFF;

  RegRdMux: process (VMERdAddr, CRegRdData, CRegRdOK, Loc_test1, Loc_test7) begin
    case VMERdAddr(19 downto 2) is
    when C_Reg_cregs_splitaddr_test1 => 
      Loc_RegRdData <= Loc_test1(31 downto 0);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_splitaddr_test7 => 
      Loc_RegRdData <= Loc_test7(31 downto 0);
      Loc_RegRdOK <= '1';
    when others =>
      Loc_RegRdData <= CRegRdData;
      Loc_RegRdOK <= CRegRdOK;
    end case;
  end process RegRdMux;

  RegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      RegRdData <= Loc_RegRdData;
      RegRdOK <= Loc_RegRdOK;
    end if;
  end process RegRdMux_DFF;
  RegRdDone <= Loc_VMERdMem(2) and RegRdOK;
  RegWrDone <= Loc_VMEWrMem(1) and CRegWrOK;
  RegRdError <= Loc_VMERdMem(2) and not RegRdOK;
  RegWrError <= Loc_VMEWrMem(1) and not CRegWrOK;
  Loc_MemRdData <= RegRdData;
  Loc_MemRdDone <= RegRdDone;
  Loc_MemRdError <= RegRdError;
  MemRdData <= Loc_MemRdData;
  MemRdDone <= Loc_MemRdDone;
  MemRdError <= Loc_MemRdError;
  Loc_MemWrDone <= RegWrDone;
  Loc_MemWrError <= RegWrError;
  MemWrDone <= Loc_MemWrDone;
  MemWrError <= Loc_MemWrError;
  RdData <= MemRdData;
  RdDone <= MemRdDone;
  WrDone <= MemWrDone;
  RdError <= MemRdError;
  WrError <= MemWrError;

  StrobeSeq: process (Clk) begin
    if rising_edge(Clk) then
      Loc_VMERdMem <= Loc_VMERdMem(1 downto 0) & VMERdMem;
      Loc_VMEWrMem <= Loc_VMEWrMem(0) & VMEWrMem;
    end if;
  end process StrobeSeq;
  VMERdData <= RdData;
  VMERdDone <= RdDone;
  VMEWrDone <= WrDone;
  VMERdError <= RdError;
  VMEWrError <= WrError;
end syn;
