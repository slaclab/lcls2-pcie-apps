-------------------------------------------------------------------------------
-- File       : AppPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-04
-- Last update: 2017-12-10
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;

package AppPkg is

   constant APP_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => DMA_AXIS_CONFIG_C.TSTRB_EN_C,
      TDATA_BYTES_C => 4,               -- 32-bit interface
      TDEST_BITS_C  => DMA_AXIS_CONFIG_C.TDEST_BITS_C,
      TID_BITS_C    => DMA_AXIS_CONFIG_C.TID_BITS_C,
      TKEEP_MODE_C  => DMA_AXIS_CONFIG_C.TKEEP_MODE_C,
      TUSER_BITS_C  => DMA_AXIS_CONFIG_C.TUSER_BITS_C,
      TUSER_MODE_C  => DMA_AXIS_CONFIG_C.TUSER_MODE_C);

   type EvrToPgpType is record
      run     : sl;
      accept  : sl;
      seconds : slv(31 downto 0);
      offset  : slv(31 downto 0);
   end record;
   constant EVR_TO_PGP_INIT_C : EvrToPgpType := (
      run     => '0',
      accept  => '0',
      seconds => (others => '0'),
      offset  => (others => '0'));

   type TrigLutInType is record
      raddr : slv(7 downto 0);
   end record;
   type TrigLutInArray is array (integer range<>) of TrigLutInType;
   type TrigLutInVectorArray is array (integer range<>, integer range<>) of TrigLutInType;
   constant TRIG_LUT_IN_INIT_C : TrigLutInType := (
      raddr => (others => '0'));

   type TrigLutOutType is record
      accept    : sl;
      seconds   : slv(31 downto 0);
      offset    : slv(31 downto 0);
      acceptCnt : slv(31 downto 0);
   end record;
   type TrigLutOutArray is array (integer range<>) of TrigLutOutType;
   type TrigLutOutVectorArray is array (integer range<>, integer range<>) of TrigLutOutType;
   constant TRIG_LUT_OUT_INIT_C : TrigLutOutType := (
      accept    => '0',
      seconds   => (others => '0'),
      offset    => (others => '0'),
      acceptCnt => (others => '0'));

   type ConfigType is record
      rxVcBlowoff   : slv(3 downto 0);
      gtDrpOverride : sl;
      txDiffCtrl    : slv(3 downto 0);
      txPreCursor   : slv(4 downto 0);
      txPostCursor  : slv(4 downto 0);
      qPllRxSelect  : slv(1 downto 0);
      qPllTxSelect  : slv(1 downto 0);
      enableTrig    : sl;
      runCode       : slv(7 downto 0);
      acceptCode    : slv(7 downto 0);
      enHeaderCheck : slv(3 downto 0);
      runDelay      : slv(31 downto 0);
      acceptDelay   : slv(31 downto 0);
      acceptCntRst  : sl;
      evrOpCodeMask : sl;
      evrSyncSel    : sl;
      evrSyncEn     : sl;
      evrSyncWord   : slv(31 downto 0);
   end record;
   constant CONFIG_INIT_C : ConfigType := (
      rxVcBlowoff   => "0000",
      gtDrpOverride => '0',
      txDiffCtrl    => "1000",
      txPreCursor   => "00000",
      txPostCursor  => "00000",
      qPllRxSelect  => "11",
      qPllTxSelect  => "11",
      enableTrig    => '0',
      runCode       => (others => '0'),
      acceptCode    => (others => '0'),
      enHeaderCheck => (others => '0'),
      runDelay      => (others => '0'),
      acceptDelay   => (others => '0'),
      acceptCntRst  => '0',
      evrOpCodeMask => '0',
      evrSyncSel    => '0',
      evrSyncEn     => '0',
      evrSyncWord   => (others => '0'));

   type StatusType is record
      lutDrop       : slv(3 downto 0);
      fifoError     : slv(3 downto 0);
      vcPause       : slv(3 downto 0);
      vcOverflow    : slv(3 downto 0);
      evrSyncStatus : sl;
      acceptCnt     : slv(31 downto 0);
   end record;
   constant STATUS_INIT_C : StatusType := (
      lutDrop       => (others => '0'),
      fifoError     => (others => '0'),
      vcPause       => (others => '0'),
      vcOverflow    => (others => '0'),
      evrSyncStatus => '0',
      acceptCnt     => (others => '0'));

end package AppPkg;
