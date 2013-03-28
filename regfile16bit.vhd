library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package regfile16bit_comp is
    type rf_muxes is record
        i : std_logic_vector(2 downto 0);   -- Destination 16-bit register selector
        o : std_logic_vector(2 downto 0);   -- Source 16-bit register selector to addr, internal datapath
        d : std_logic_vector(3 downto 0);   -- Source 8-bit register selector to odata
        a : std_logic_vector(1 downto 0);   -- Second operand selector (Sign extended idata, HL, -1, +1, 0...)
        ce : std_logic_vector(1 downto 0);  -- Clock enable and 8/16-bit selector for register input (-, lsB, msB, 16-bit)
    end record;

    component regfile16bit
    Port (  idata : in std_logic_vector(7 downto 0);    -- Incoming 8-bit data
            odata : out std_logic_vector(7 downto 0);   -- Outgoing 8-bit data
            addr : out std_logic_vector(15 downto 0);   -- Outgoing 16-bit address
            muxes : in rf_muxes;
            zout : out std_logic;
            nout : out std_logic;
            hout : out std_logic;
            cout : out std_logic;
            TCK : IN STD_LOGIC;
            TDL : IN STD_LOGIC;
            TDI : IN STD_LOGIC;
            TDO : OUT STD_LOGIC;
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC );
    end component;
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.regfile16bit_comp.all;

entity regfile16bit is
    Port (  idata : in std_logic_vector(7 downto 0);    -- Incoming 8-bit data
            odata : out std_logic_vector(7 downto 0);   -- Outgoing 8-bit data
            addr : out std_logic_vector(15 downto 0);   -- Outgoing 16-bit address
            muxes : in rf_muxes;
            zout : out std_logic;
            nout : out std_logic;
            hout : out std_logic;
            cout : out std_logic;
            TCK : IN STD_LOGIC;
            TDL : IN STD_LOGIC;
            TDI : IN STD_LOGIC;
            TDO : OUT STD_LOGIC;
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC );
end regfile16bit;

architecture Behaviour of regfile16bit is

    type regfile is array(5 downto 0) of std_logic_vector(15 downto 0);
    signal rfile : regfile;

    signal obus, abus : std_logic_vector(15 downto 0);

    signal sum : std_logic_vector(15 downto 0);

    signal bscan : std_logic_vector(79 downto 0);

begin

    -- Outshifter --

    process(TCK, RST)
    begin
        if RST = '1' then
            TDO <= '0';
            bscan <= (others => '0');
        elsif rising_edge(TCK) then
            if TDL = '1' then
                TDO <= rfile(4)(15);
                bscan <= rfile(4)(14 downto 0) & rfile(3) & rfile(2) & rfile(1) & rfile(0) & TDI;
            else
                TDO <= bscan(79);
                bscan <= bscan(78 downto 0) & TDI;
            end if;
        end if;
    end process;

    -- Flags Z and N are either reset or left unchanged
    ZOUT <= '0';
    NOUT <= '0';

    with muxes.o select
        obus <= rfile(0) when "000",    -- BC
                rfile(1) when "001",    -- DE
                rfile(2) when "010",    -- HL
                rfile(3) when "011",    -- SP
                rfile(4) when "100",    -- PC
                X"FF00" when "101",     -- Legacy, probably not used
                X"0000" when others;

    with muxes.d select
        odata <= rfile(0)(15 downto 8) when "0000",  -- B
                 rfile(0)( 7 downto 0) when "0001",  -- C
                 rfile(1)(15 downto 8) when "0010",  -- D
                 rfile(1)( 7 downto 0) when "0011",  -- E
                 rfile(2)(15 downto 8) when "0100",  -- H
                 rfile(2)( 7 downto 0) when "0101",  -- L
                 rfile(3)(15 downto 8) when "0110",  -- S
                 rfile(3)( 7 downto 0) when "0111",  -- P
                 rfile(4)(15 downto 8) when "1000",  -- P
                 rfile(4)( 7 downto 0) when others;  -- C

    with muxes.a select
        abus <= idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata(7) & idata when "00",
                rfile(2) when "01",     -- HL
                X"FFFF" when "10",      -- -1
                X"0001" when "11",      -- +1
                X"0000" when others;
    addr <= obus;

    REGFILE_IN : process(CLK, RST, muxes.ce)
        variable lo : std_logic_vector(12 downto 0);
        variable hi : std_logic_vector(4 downto 0);
    begin
        if (RST = '1') then
            for I in rfile'range loop
                if I = 4 then
                    rfile(4) <= X"0000";
                else
                    rfile(I) <= X"DEAD";            -- Initialize registers nonzero, as in reality
                end if;
            end loop;
        elsif rising_edge(CLK) then
            for I in rfile'range loop
                if ( muxes.i = I ) then
                    case muxes.ce is
                        when "11" =>                                    -- 16-bit path into 16-bit register
                            lo := ('0' & obus(11 downto 0)) + ('0' & abus(11 downto 0));                        -- lower 3 nibbles
                            hi := ('0' & obus(15 downto 12)) + ('0' & abus(15 downto 12)) + ("0000" & lo(12));  -- high nibble
                            rfile(I) <= hi(3 downto 0) & lo(11 downto 0);
                            HOUT <= lo(12);
                            COUT <= hi(4);
                        when "10" => rfile(I)(15 downto 8) <= idata;    -- IDATA into msB
                        when "01" => rfile(I)(7 downto 0) <= idata;     -- IDATA into lsB
                        when others => null;                            -- NOP
                    end case;
                end if;
            end loop;
        end if;
    end process;

end Behaviour;

