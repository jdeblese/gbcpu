library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity regfile16bit is
	Port (  idata : in std_logic_vector(7 downto 0);
            odata : out std_logic_vector(7 downto 0);
            addr : out std_logic_vector(15 downto 0);
            imux : in std_logic_vector(2 downto 0);
            omux : in std_logic_vector(2 downto 0);
            amux : in std_logic_vector(1 downto 0);
            bmux : in std_logic;
            ce : in std_logic_vector(1 downto 0);
			CLK : IN STD_LOGIC;
			RST : IN STD_LOGIC );
end regfile16bit;

architecture Behaviour of regfile16bit is

    type regfile is array(5 downto 0) of std_logic_vector(15 downto 0);
    signal rfile : regfile; -- rfile(2) is HL
--  signal BC, DE, HL, SP, PC : STD_LOGIC_VECTOR(15 downto 0);

    signal obus, abus : std_logic_vector(15 downto 0);

begin

    with omux select
        obus <= rfile(0) when "000",
                rfile(1) when "001",
                rfile(2) when "010",
                rfile(3) when "011",
                rfile(4) when "100",
                X"FF00" when "101",
                X"0000" when others;

    with amux select
        abus <= idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata when "00",
                rfile(2) when "01",     -- HL
                X"FFFF" when "10",
                X"0001" when "11",
                X"0000" when others;
    addr <= obus;

    with bmux select
        odata <= obus(7 downto 0) when '0',
                 obus(15 downto 8) when '1',
                 X"00" when others;

    REGFILE_IN : process(CLK, RST, ce)
    begin
        if (RST = '1') then
            for I in rfile'range loop
                rfile(I) <= X"0000";
            end loop;
        elsif (falling_edge(CLK)) then
            for I in rfile'range loop
                if ( imux = I ) then
                    case ce is
                        when "11" => rfile(I) <= obus + abus;
                        when "10" => rfile(I)(15 downto 8) <= idata;
                        when "01" => rfile(I)(7 downto 0) <= idata;
                        when others => null;
                    end case;
                end if;
            end loop;
        end if;
    end process;

end Behaviour;

