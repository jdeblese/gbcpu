library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity regfile is
	Port (	DBUS : inout STD_LOGIC_VECTOR(7 downto 0);
			DOMUX : in STD_LOGIC_VECTOR(2 downto 0);
			DIMUX : in STD_LOGIC_VECTOR(2 downto 0);
            CE : IN STD_LOGIC;
			CLK : IN STD_LOGIC;
			RST : IN STD_LOGIC );
end regfile;

architecture Struct of regfile is

    signal B, C, D, E, H, L : STD_LOGIC_VECTOR(7 downto 0);

begin

    with DOMUX select
        DBUS <= B when "000",
                C when "001",
                D when "010",
                E when "011",
                H when "100",
                L when "101",
                "ZZZZZZZZ" when others;

    REGFILE_IN : process(CLK, RST, CE)
    begin
        if (RST = '1') then
            B <= "00000001";
            C <= "00000010";
            D <= "00000100";
            E <= "00001000";
            H <= "00010000";
            L <= "00100000";
        elsif (falling_edge(CLK) and CE = '1') then
            case DIMUX is
                when "000" => B <= DBUS;
                when "001" => C <= DBUS;
                when "010" => D <= DBUS;
                when "011" => E <= DBUS;
                when "100" => H <= DBUS;
                when "101" => L <= DBUS;
                when others => null;
            end case;
        end if;
    end process;

end Struct;

