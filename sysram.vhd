library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package sysram_comp is
	component sysram
	Port (
		RST : in STD_LOGIC;
		CLK : in  STD_LOGIC;
		ADDR : in STD_LOGIC_VECTOR(15 downto 0);
		RD_D : out STD_LOGIC_VECTOR(7 downto 0);
		WR_D : in STD_LOGIC_VECTOR(7 downto 0);
		OE : in STD_LOGIC;
		WR : in STD_LOGIC);
	end component;
end package;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;


entity sysram is
	Port (
		RST : in STD_LOGIC;
		CLK : in  STD_LOGIC;
		ADDR : in STD_LOGIC_VECTOR(15 downto 0);
		RD_D : out STD_LOGIC_VECTOR(7 downto 0);
		WR_D : in STD_LOGIC_VECTOR(7 downto 0);
		OE : in STD_LOGIC;
		WR : in STD_LOGIC);
end sysram;

architecture DataPath of sysram is

	type ram_in is record
		idata : std_logic_vector(31 downto 0);
		ipar : std_logic_vector(3 downto 0);
		addr : std_logic_vector(13 downto 0);
		wen : std_logic_vector(3 downto 0);
	end record;
	type inputs_type is array (3 downto 0) of ram_in;
	signal inputs : inputs_type;

	type ram_out is record
		odata : std_logic_vector(31 downto 0);
		opar : std_logic_vector(3 downto 0);
	end record;
	type outputs_type is array (3 downto 0) of ram_out;
	signal outputs : outputs_type;

	type loopconv is array (3 downto 0) of std_logic_vector(1 downto 0);
	constant lc : loopconv := ("11", "10", "01", "00");

begin

	-- Memory mapping

	process(ADDR, WR, WR_D)
	begin
		for I in 0 to 3 loop
			-- E000 mirrors C000
			if ADDR(15 downto 14) = "11" and ADDR(12 downto 11) = lc(I) then
				inputs(I).wen <= WR&WR&WR&WR;
			else
				inputs(I).wen <= "0000";
			end if;

			inputs(I).addr(13 downto 3) <= ADDR(10 downto 0);
			inputs(I).addr(2 downto 0)  <= (others => '0');

			inputs(I).ipar <= (others => '0');
			inputs(I).idata(31 downto 8) <= (others => '0');
			inputs(I).idata(7 downto 0) <= WR_D;
		end loop;
	end process;

	RD_D <= "ZZZZZZZZ" WHEN OE = '0' ELSE
			outputs(0).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11000" ELSE  -- C000-C7FF
			outputs(1).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11001" ELSE  -- C800-CFFF
			outputs(2).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11010" ELSE  -- D000-D7FF
			outputs(3).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11011" ELSE  -- D800-DFFF
			-- E000 mirrors C000
			outputs(0).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11100" ELSE  -- E000-E7FF
			outputs(1).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11101" ELSE  -- E800-EFFF
			outputs(2).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11110" ELSE  -- F000-F7FF
			outputs(3).odata(7 downto 0) WHEN ADDR(15 downto 11) = "11111" ELSE  -- F800-FFFF
	        "ZZZZZZZZ";

	-- Memory declaration

	sysram00 : RAMB16BWER
	generic map (
		SIM_DEVICE => "SPARTAN6",
		DATA_WIDTH_A => 9,
		DATA_WIDTH_B => 9,
		WRITE_MODE_A => "WRITE_FIRST",
		WRITE_MODE_B => "WRITE_FIRST",
		-- DOA_REG/DOB_REG: Optional output register (0 or 1)
		DOA_REG => 0,
		DOB_REG => 0,
		-- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		EN_RSTRAM_A => TRUE,
		EN_RSTRAM_B => TRUE,
		-- INIT_A/INIT_B: Initial values on output port
		INIT_A => X"000000000",
		INIT_B => X"000000000",
		-- RSTTYPE: "SYNC" or "ASYNC"
		RSTTYPE => "SYNC",
		-- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		RST_PRIORITY_A => "CE",
		RST_PRIORITY_B => "CE",
		-- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		SIM_COLLISION_CHECK => "ALL",
		-- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		-- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
		SRVAL_A => X"000000000",
		SRVAL_B => X"000000000"
	)
	port map (
		-- Port A
		DOA => outputs(0).odata,
		DOPA => outputs(0).opar,
		ADDRA => inputs(0).addr,
		CLKA => CLK,
		ENA => '1',
		REGCEA => '0',
		RSTA => RST,
		WEA => inputs(0).wen,
		DIA => inputs(0).idata,
		DIPA => inputs(0).ipar,
		-- Port B
		ADDRB => "00" & X"000",   -- 14-bit input: B port address input
		CLKB => '0',	  -- 1-bit input: B port clock input
		ENB => '0',	   -- 1-bit input: B port enable input
		REGCEB => '0',	-- 1-bit input: B port register clock enable input
		RSTB => '0',	  -- 1-bit input: B port register set/reset input
		WEB => "0000",	-- 4-bit input: Port B byte-wide write enable input
		DIB => X"00000000",	   -- 32-bit input: B port data input
		DIPB => "0000"	-- 4-bit input: B port parity input
	);

	sysram01 : RAMB16BWER
	generic map (
		SIM_DEVICE => "SPARTAN6",
		DATA_WIDTH_A => 9,
		DATA_WIDTH_B => 9,
		WRITE_MODE_A => "WRITE_FIRST",
		WRITE_MODE_B => "WRITE_FIRST",
		-- DOA_REG/DOB_REG: Optional output register (0 or 1)
		DOA_REG => 0,
		DOB_REG => 0,
		-- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		EN_RSTRAM_A => TRUE,
		EN_RSTRAM_B => TRUE,
		-- INIT_A/INIT_B: Initial values on output port
		INIT_A => X"000000000",
		INIT_B => X"000000000",
		-- RSTTYPE: "SYNC" or "ASYNC"
		RSTTYPE => "SYNC",
		-- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		RST_PRIORITY_A => "CE",
		RST_PRIORITY_B => "CE",
		-- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		SIM_COLLISION_CHECK => "ALL",
		-- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		-- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
		SRVAL_A => X"000000000",
		SRVAL_B => X"000000000"
	)
	port map (
		-- Port A
		DOA => outputs(1).odata,
		DOPA => outputs(1).opar,
		ADDRA => inputs(1).addr,
		CLKA => CLK,
		ENA => '1',
		REGCEA => '0',
		RSTA => RST,
		WEA => inputs(1).wen,
		DIA => inputs(1).idata,
		DIPA => inputs(1).ipar,
		-- Port B
		ADDRB => "00" & X"000",   -- 14-bit input: B port address input
		CLKB => '0',	  -- 1-bit input: B port clock input
		ENB => '0',	   -- 1-bit input: B port enable input
		REGCEB => '0',	-- 1-bit input: B port register clock enable input
		RSTB => '0',	  -- 1-bit input: B port register set/reset input
		WEB => "0000",	-- 4-bit input: Port B byte-wide write enable input
		DIB => X"00000000",	   -- 32-bit input: B port data input
		DIPB => "0000"	-- 4-bit input: B port parity input
	);

	sysram02 : RAMB16BWER
	generic map (
		SIM_DEVICE => "SPARTAN6",
		DATA_WIDTH_A => 9,
		DATA_WIDTH_B => 9,
		WRITE_MODE_A => "WRITE_FIRST",
		WRITE_MODE_B => "WRITE_FIRST",
		-- DOA_REG/DOB_REG: Optional output register (0 or 1)
		DOA_REG => 0,
		DOB_REG => 0,
		-- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		EN_RSTRAM_A => TRUE,
		EN_RSTRAM_B => TRUE,
		-- INIT_A/INIT_B: Initial values on output port
		INIT_A => X"000000000",
		INIT_B => X"000000000",
		-- RSTTYPE: "SYNC" or "ASYNC"
		RSTTYPE => "SYNC",
		-- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		RST_PRIORITY_A => "CE",
		RST_PRIORITY_B => "CE",
		-- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		SIM_COLLISION_CHECK => "ALL",
		-- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		-- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
		SRVAL_A => X"000000000",
		SRVAL_B => X"000000000"
	)
	port map (
		-- Port A
		DOA => outputs(2).odata,
		DOPA => outputs(2).opar,
		ADDRA => inputs(2).addr,
		CLKA => CLK,
		ENA => '1',
		REGCEA => '0',
		RSTA => RST,
		WEA => inputs(2).wen,
		DIA => inputs(2).idata,
		DIPA => inputs(2).ipar,
		-- Port B
		ADDRB => "00" & X"000",   -- 14-bit input: B port address input
		CLKB => '0',	  -- 1-bit input: B port clock input
		ENB => '0',	   -- 1-bit input: B port enable input
		REGCEB => '0',	-- 1-bit input: B port register clock enable input
		RSTB => '0',	  -- 1-bit input: B port register set/reset input
		WEB => "0000",	-- 4-bit input: Port B byte-wide write enable input
		DIB => X"00000000",	   -- 32-bit input: B port data input
		DIPB => "0000"	-- 4-bit input: B port parity input
	);

	sysram03 : RAMB16BWER
	generic map (
		SIM_DEVICE => "SPARTAN6",
		DATA_WIDTH_A => 9,
		DATA_WIDTH_B => 9,
		WRITE_MODE_A => "WRITE_FIRST",
		WRITE_MODE_B => "WRITE_FIRST",
		-- DOA_REG/DOB_REG: Optional output register (0 or 1)
		DOA_REG => 0,
		DOB_REG => 0,
		-- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
		EN_RSTRAM_A => TRUE,
		EN_RSTRAM_B => TRUE,
		-- INIT_A/INIT_B: Initial values on output port
		INIT_A => X"000000000",
		INIT_B => X"000000000",
		-- RSTTYPE: "SYNC" or "ASYNC"
		RSTTYPE => "SYNC",
		-- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
		RST_PRIORITY_A => "CE",
		RST_PRIORITY_B => "CE",
		-- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
		SIM_COLLISION_CHECK => "ALL",
		-- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
		-- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
		SRVAL_A => X"000000000",
		SRVAL_B => X"000000000"
	)
	port map (
		-- Port A
		DOA => outputs(3).odata,
		DOPA => outputs(3).opar,
		ADDRA => inputs(3).addr,
		CLKA => CLK,
		ENA => '1',
		REGCEA => '0',
		RSTA => RST,
		WEA => inputs(3).wen,
		DIA => inputs(3).idata,
		DIPA => inputs(3).ipar,
		-- Port B
		ADDRB => "00" & X"000",   -- 14-bit input: B port address input
		CLKB => '0',	  -- 1-bit input: B port clock input
		ENB => '0',	   -- 1-bit input: B port enable input
		REGCEB => '0',	-- 1-bit input: B port register clock enable input
		RSTB => '0',	  -- 1-bit input: B port register set/reset input
		WEB => "0000",	-- 4-bit input: Port B byte-wide write enable input
		DIB => X"00000000",	   -- 32-bit input: B port data input
		DIPB => "0000"	-- 4-bit input: B port parity input
	);

end DataPath;
