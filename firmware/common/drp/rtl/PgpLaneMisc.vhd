-------------------------------------------------------------------------------
-- File       : PgpLaneMisc.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-11-14
-- Last update: 2018-08-19
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'SLAC PGP Gen3 Card'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC PGP Gen3 Card', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity PgpLaneMisc is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      pgpClk          : in  sl;
      pgpRst          : in  sl;
      pgpFrameDrop    : in  sl;
      pgpFrameTrunc   : in  sl;
      pgpRxVcBlowoff  : out slv(15 downto 0);
      pgpRxLoopback   : out slv( 2 downto 0);
      pgpRxReset      : out sl;
      pgpLaneId       : out slv(31 downto 0);
      remLinkDet      : in  sl               := '0';
      remLinkId       : in  slv(31 downto 0) := (others=>'0');
      -- AXI-Lite Register Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneMisc;

architecture rtl of PgpLaneMisc is

   type RegType is record
      pgpRxVcBlowoff : slv(15 downto 0);
      pgpRxLoopback  : slv( 2 downto 0);
      pgpRxReset     : sl;
      cntRst         : sl;
      pgpLaneId      : slv(31 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      pgpRxVcBlowoff => (others => '0'),
      pgpRxLoopback  => (others => '0'),
      pgpRxReset     => '0',
      cntRst         => '0',
      pgpLaneId      => (others=>'1'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal cntv : SlVectorArray(1 downto 0, 31 downto 0);
   
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rremLinkId, sremLinkId : slv(31 downto 0);
   
begin

   U_SyncStatus : entity work.SyncStatusVector
     generic map ( WIDTH_G => 2 )
     port map ( statusIn(0)  => pgpFrameDrop,
                statusIn(1)  => pgpFrameTrunc,
                cntRstIn     => r.cntRst,
                rollOverEnIn => (others=>'1'),
                cntOut       => cntv,
                wrClk        => pgpClk,
                rdClk        => axilClk,
                rdRst        => axilRst );

   --------------------- 
   -- AXI Lite Interface
   --------------------- 
   comb : process (axilReadMaster, axilRst, axilWriteMaster, r, cntv, sremLinkId) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      axiSlaveRegister (regCon, x"00", 0, v.pgpRxVcBlowoff);
      axiSlaveRegister (regCon, x"00",16, v.pgpRxLoopback);
      axiSlaveRegister (regCon, x"00",31, v.pgpRxReset);

      v.cntRst := '0';
      axiWrDetect   (regCon, x"04", v.cntRst);
      
      axiSlaveRegisterR(regCon, x"08",0, muxSlVectorArray(cntv, 0));
      axiSlaveRegisterR(regCon, x"0C",0, muxSlVectorArray(cntv, 1));

      axiSlaveRegister (regCon, x"10", 0, v.pgpLaneId);
      axiSlaveRegisterR(regCon, x"14", 0, sremLinkId);
      
      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   pseq : process (pgpClk) is
   begin
     if rising_edge(pgpClk) then
       if remLinkDet = '1' then
         rremLinkId <= remLinkId;
       end if;
     end if;
   end process; pseq;

   SyncRemLinkId : entity work.SynchronizerVector
     generic map ( WIDTH_G => 32 )'
     port map ( clk      => axilClk,
                dataIn   => rremLinkId,
                dataOut  => sremLinkId );
   
   Sync_pgpRxVcBlowoff : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => pgpClk,
         dataIn  => r.pgpRxVcBlowoff,
         dataOut => pgpRxVcBlowoff);

   Sync_pgpRxLoopback : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         clk     => pgpClk,
         dataIn  => r.pgpRxLoopback,
         dataOut => pgpRxLoopback);

   Sync_pgpRxReset : entity work.Synchronizer
      generic map (
         TPD_G   => TPD_G )
      port map (
         clk     => pgpClk,
         dataIn  => r.pgpRxReset,
         dataOut => pgpRxReset);

   Sync_pgpLaneId : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 32)
      port map (
         clk     => pgpClk,
         dataIn  => r.pgpLaneId,
         dataOut => pgpLaneId);
   
end rtl;
