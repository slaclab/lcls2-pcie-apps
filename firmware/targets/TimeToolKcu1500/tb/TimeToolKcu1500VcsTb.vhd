-------------------------------------------------------------------------------
-- File       : TimeToolKcu1500VcsTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the FPGA module
-------------------------------------------------------------------------------
-- This file is part of 'Camera link gateway'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'Camera link gateway', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.I2cPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

entity TimeToolKcu1500VcsTb is end TimeToolKcu1500VcsTb;

architecture testbed of TimeToolKcu1500VcsTb is

   constant TPD_G : time := 1 ns;

   signal userClkP : sl := '0';
   signal userClkN : sl := '1';

   signal i2cClk : sl;
   signal i2cRst : sl;
   signal scl    : sl;
   signal sda    : sl;
   signal sc     : slv(7 downto 0);
   signal sd     : slv(7 downto 0);

   signal rst0 : sl;
   signal rst4 : sl;

   signal wrData : slv(7 downto 0);

   signal i2ci : i2c_in_type;
   signal i2co : i2c_out_type;   

begin

   U_ClkPgp : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,   -- 156.25 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => userClkP,
         clkN => userClkN);

   U_Fpga : entity work.TimeToolKcu1500
      generic map (
         TPD_G          => TPD_G,
         ROGUE_SIM_EN_G => true,
         BUILD_INFO_G   => BUILD_INFO_C)
      port map (
         ---------------------
         --  Application Ports
         ---------------------
         -- QSFP[0] Ports
         qsfp0RefClkP => (others => '0'),
         qsfp0RefClkN => (others => '1'),
         qsfp0RxP     => (others => '0'),
         qsfp0RxN     => (others => '1'),
         qsfp0TxP     => open,
         qsfp0TxN     => open,
         -- QSFP[1] Ports
         qsfp1RefClkP => (others => '0'),
         qsfp1RefClkN => (others => '1'),
         qsfp1RxP     => (others => '0'),
         qsfp1RxN     => (others => '1'),
         qsfp1TxP     => open,
         qsfp1TxN     => open,
         --------------
         --  Core Ports
         --------------
         -- System Ports
         emcClk       => '0',
         userClkP     => userClkP,
         userClkN     => userClkN,
         -- QSFP[0] Ports
         qsfp0RstL    => open,
         qsfp0LpMode  => open,
         qsfp0ModSelL => open,
         qsfp0ModPrsL => '1',
         -- QSFP[1] Ports
         qsfp1RstL    => open,
         qsfp1LpMode  => open,
         qsfp1ModSelL => open,
         qsfp1ModPrsL => '1',
         scl          => scl,
         sda          => sda,
         -- Boot Memory Ports 
         flashCsL     => open,
         flashMosi    => open,
         flashMiso    => '1',
         flashHoldL   => open,
         flashWp      => open,
         -- PCIe Ports
         pciRstL      => '1',
         pciRefClkP   => '0',
         pciRefClkN   => '1',
         pciRxP       => (others => '0'),
         pciRxN       => (others => '1'),
         pciTxP       => open,
         pciTxN       => open);

   U_ClkI2c : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 8.0 ns,   -- 156.25 MHz
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => i2cClk,
         rst  => i2cRst);

   scl <= 'H';
   sda <= 'H';

   sc <= (others => 'H');
   sd <= (others => 'H');

--    U_Tca9548a_1 : entity surf.Tca9548a
--       generic map (
--          TPD_G  => TPD_G,
--          ADDR_G => "1110100")
--       port map (
--          scl => scl,                    -- [inout]
--          sda => sda,                    -- [inout]
--          sc  => sc,                     -- [inout]
--          sd  => sd);                    -- [inout]

   U_I2cRegSlave_1 : entity surf.I2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => conv_integer("1110100"),
         OUTPUT_EN_POLARITY_G => 0,
--         FILTER_G             => FILTER_G,
         ADDR_SIZE_G          => 0,
         DATA_SIZE_G          => 1,
         ENDIANNESS_G         => 0)
      port map (
         sRst   => i2cRst,              -- [in]
         clk    => i2cClk,              -- [in]
         wrEn   => open,                -- [out]
         wrData => wrData,              -- [out]
--         rdEn   => rdEn,                -- [out]
         rdData => wrData,              -- [in]
         i2ci   => i2ci,                -- [in]
         i2co   => i2co);               -- [out]

   sda      <= i2co.sda when i2co.sdaoen = '0' else 'Z';
   i2ci.sda <= sda;

   scl      <= i2co.scl when i2co.scloen = '0' else 'Z';
   i2ci.scl <= scl;
   

   rst0 <= i2cRst or not wrData(0);
   rst4 <= i2cRst or not wrData(4);

   U_i2cRamSlave_0 : entity surf.i2cRamSlave
      generic map (
         TPD_G        => TPD_G,
         I2C_ADDR_G   => conv_integer("1010000"),
         TENBIT_G     => 0,
         FILTER_G     => 4,
         ADDR_SIZE_G  => 1,
         DATA_SIZE_G  => 1,
         ENDIANNESS_G => 0)
      port map (
         clk    => i2cClk,              -- [in]
         rst    => rst0,                -- [in]
         i2cSda => sda,                 -- [inout]
         i2cScl => scl);                -- [inout]

   U_i2cRamSlave_4 : entity surf.i2cRamSlave
      generic map (
         TPD_G        => TPD_G,
         I2C_ADDR_G   => conv_integer("1010000"),  --80,
         TENBIT_G     => 0,
         FILTER_G     => 4,
         ADDR_SIZE_G  => 1,
         DATA_SIZE_G  => 1,
         ENDIANNESS_G => 0)
      port map (
         clk    => i2cClk,                         -- [in]
         rst    => rst4,                           -- [in]
         i2cSda => sda,                            -- [inout]
         i2cScl => scl);                           -- [inout]




end testbed;
