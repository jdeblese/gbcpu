library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cartram_comp is
	component cartram
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


entity cartram is
	Port (
		RST : in STD_LOGIC;
		CLK : in  STD_LOGIC;
		ADDR : in STD_LOGIC_VECTOR(15 downto 0);
		RD_D : out STD_LOGIC_VECTOR(7 downto 0);
		WR_D : in STD_LOGIC_VECTOR(7 downto 0);
		OE : in STD_LOGIC;
		WR : in STD_LOGIC);
end cartram;

architecture DataPath of cartram is

	type ram_in is record
		idata : std_logic_vector(31 downto 0);
		ipar : std_logic_vector(3 downto 0);
		addr : std_logic_vector(13 downto 0);
		wen : std_logic_vector(3 downto 0);
	end record;
	signal in01 : ram_in;

	type ram_out is record
		odata : std_logic_vector(31 downto 0);
		opar : std_logic_vector(3 downto 0);
	end record;
	signal out01 : ram_out;

begin

	in01.addr(13 downto 3) <= ADDR(10 downto 0);
	in01.addr(2 downto 0)  <= (others => '0');

	in01.ipar <= (others => '0');
	in01.idata(31 downto 8) <= (others => '0');
	in01.idata(7 downto 0) <= WR_D;
	in01.wen <= WR&WR&WR&WR WHEN ADDR(15 downto 11) = "00000" else "0000"; -- 0000-07FF

	RD_D <= "ZZZZZZZZ"              WHEN OE = '0' ELSE
			out01.odata(7 downto 0) WHEN ADDR(15 downto 11) = "00000" ELSE  -- 0000-07FF
	        "ZZZZZZZZ";

	ram01 : RAMB16BWER
	generic map (
		SIM_DEVICE => "SPARTAN6",
		DATA_WIDTH_A => 9,
		DATA_WIDTH_B => 9,
		WRITE_MODE_A => "WRITE_FIRST",
		WRITE_MODE_B => "WRITE_FIRST",
		INIT_08 => X"E66ECCDC0E0089881F1108000D000C00830073030B000DCC6666EDCE000100c3", -- 0100, logo checked by boot ROM
		INIT_09 => X"0000000000000000000000003E33B9BB9F99DCDDCCEC0E6E6367BBBB99D9DDDD", -- 0120
		INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0140
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
		DOA => out01.odata,
		DOPA => out01.opar,
		ADDRA => in01.addr,
		CLKA => CLK,
		ENA => '1',
		REGCEA => '0',
		RSTA => RST,
		WEA => in01.wen,
		DIA => in01.idata,
		DIPA => in01.ipar,
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
