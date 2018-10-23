-------------------------------------------------------------------------------
-- File       : S2mmDriver.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-03-03
-------------------------------------------------------------------------------
-- Description: Driver for Axi Data Mover S2MM interface
--   Reorders output status to return transfer results in request order.
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiDescPkg.all;

entity S2mmDriver is
  generic ( ADDR_WIDTH_G : integer := 32;
            TAG_WIDTH_G  : integer := 4;
            MAX_LENGTH_G : slv(22 downto 0) := '1' & toSlv(0,22) );
  port    ( -- Clock and reset
    -- AXI4 Interface 
    clk              : in  sl; -- 200MHz
    rst              : in  sl;
    -- Command/Status
    master           : out AxiDescMasterType  ;
    slave            : in  AxiDescSlaveType   ;
    -- Configuration
    mAddrValid       : in  sl := '1';
    mAddrIn          : in  slv(ADDR_WIDTH_G-1 downto 0);
    mTagIn           : in  slv(TAG_WIDTH_G-1 downto 0);
    mRequest         : out sl;
    --
    mReady           : in  sl;
    mTagOut          : out slv(TAG_WIDTH_G-1 downto 0);
    mLenOut          : out slv(22 downto 0);
    mComplete        : out sl );
end S2mmDriver;

architecture mapping of S2mmDriver is

  type TagState is (IDLE_T, REQUESTED_T, COMPLETED_T);
  type TagStateArray is array(natural range<>) of TagState;
  
  type RegType is record
    wrIndex        : slv(3 downto 0);  -- write request
    wcIndex        : slv(3 downto 0);  -- write complete
    tag            : TagStateArray(15 downto 0);
    master         : AxiDescMasterType;
    request        : sl;
    complete       : sl;
  end record;

  constant REG_INIT_C : RegType := (
    wrIndex        => (others=>'0'),
    wcIndex        => (others=>'0'),
    tag            => (others=>IDLE_T),
    master         => AXI_DESC_MASTER_INIT_C,
    request        => '0',
    complete       => '0' );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

begin

  U_Addr : entity work.SimpleDualPortRam
    generic map ( DATA_WIDTH_G => TAG_WIDTH_G,
                  ADDR_WIDTH_G => 4 )
    port map ( clka       => clk,
               wea        => rin.request,
               addra      => rin.tag,
               dina       => mTagIn,
               clkb       => clk,
               addrb      => r.wcIndex,
               doutb      => mTagOut );

  U_Length : entity work.SimpleDualPortRam
    generic map ( DATA_WIDTH_G => 23,
                  ADDR_WIDTH_G => 4 )
    port map ( clka       => clk,
               wea        => slave.status.tValid,
               addra      => slave.status.tData(3 downto 0),
               dina       => slave.status.tData(30 downto 8),
               clkb       => clk,
               addrb      => r.wcIndex,
               doutb      => mLenOut );

  comb : process ( r, rst, slave ) is
    variable v       : RegType;
    variable i       : integer;
    variable stag    : slv( 3 downto 0);
    variable itag    : integer;
  begin
    v := r;

    v.master.command.tLast := '1'; -- always a single word
    v.request              := '0';
    v.complete             := '0';
    
    if slave.command.tReady = '1' then
      v.master.command.tValid := '0';
    end if;

    itag := conv_integer(r.wrIndex);
    if (v.master.command.tValid = '0' and
        mAddrValid              = '1' and
        r.tag(itag)           = IDLE_T) then
      v.master.command.tData(71 downto 0) :=
        x"0" &                   -- reserved
        toSlv(itag,4) &          -- tag
        mAddrIn &                -- address[31:0]
        "01" & toSlv(0,6) &      -- EOF command
        '1' & MAX_LENGTH_G;      -- max write length
      v.wrIndex                  := r.wrIndex + 1;
      v.tag(itag)                := REQUESTED_T;
      v.master.command.tValid    := '1';
      v.request                  := '1';
    end if;

    stag := slave.status.tData(3 downto 0);
    itag := conv_integer(stag);
    if slave.status.tValid = '1' then
      v.master.status.tReady := '1';
      v.tag(itag)            := COMPLETED_T;
    end if;
    
    itag := conv_integer(r.wcIndex);
    if (r.tag(itag) = COMPLETED_T and
        mReady = '1') then
      v.tag(itag)   := IDLE_T;
      v.wcIndex     := r.wcIndex + 1;
      v.complete    := '1';
    end if;

    mRequest  <= v.request;
    mComplete <= v.complete;
    master    <= r.master;
    
    if rst = '1' then
      v := REG_INIT_C;
    end if;
    
    rin <= v;

  end process comb;

  seq: process(clk) is
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process seq;

end mapping;



