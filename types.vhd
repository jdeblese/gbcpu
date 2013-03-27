library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package types_comp is
	type ram_in is record
		idata : std_logic_vector(31 downto 0);
		ipar : std_logic_vector(3 downto 0);
		addr : std_logic_vector(13 downto 0);
		wen : std_logic_vector(3 downto 0);
	end record;

	type ram_out is record
		odata : std_logic_vector(31 downto 0);
		opar : std_logic_vector(3 downto 0);
	end record;
end package;
