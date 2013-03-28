library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- FIXME: How does starting, stopping and changing the timer affect
--  the phase of the clock divider, if at all?

entity timer is
    Port (  WR_D    : in std_logic_vector(7 downto 0);
            RD_D    : out std_logic_vector(7 downto 0);
            ABUS    : in std_logic_vector(15 downto 0);
            WR_EN   : in std_logic;
            INT     : out std_logic;
            CLK     : in std_logic;
            RST     : in std_logic );
end timer;

architecture Behaviour of timer is

    -- Registers
    signal div, tima, tma, tac : std_logic_vector(7 downto 0);

    signal clkgen : std_logic_vector(9 downto 0);

begin

    clkproc : process(CLK, RST)
    begin
        if RST = '1' then
            clkgen <= "0000000000";
        elsif rising_edge(CLK) then
            clkgen <= clkgen + "1";
        end if;
    end process;

    RD_D <= "ZZZZZZZZ" when WR_EN = '1' else
            div  when ABUS = X"FF04" else
            tima when ABUS = X"FF05" else
            tma  when ABUS = X"FF06" else
            tac  when ABUS = X"FF07" else
            "ZZZZZZZZ";

    inproc : process(CLK, RST)
    begin
        if RST = '1' then
            tma <= X"dd";       -- Don't initialize to zero
            tac <= X"02";       -- Don't initialize to zero
        elsif rising_edge(CLK) then
            if WR_EN = '1' and ABUS = X"FF06" then
                tma <= WR_D;
            elsif WR_EN = '1' and ABUS = X"FF07" then
                tac(2 downto 0) <= WR_D(2 downto 0);        -- FIXME: Are only the lower 3 bits writable?
            end if;
        end if;
    end process;

    divproc : process(CLK, RST)
        variable cen_old : std_logic;
    begin
        if RST = '1' then
            div <= X"dd";       -- Don't initialize to zero
        elsif rising_edge(CLK) then

            -- reset 'div' to zero when written to
            if WR_EN = '1' and ABUS = X"FF04" then
                div <= X"00";

            -- increment 'div' on the rising edge of CPU CLK / 2^8, if enabled by tac(2)
            elsif tac(2) = '1' and clkgen(7) = '1' and cen_old = '0' then
                if div = X"FF" then
                    div <= X"00";
                else
                    div <= tima + "1";
                end if;
            end if;

            cen_old := clkgen(7);
        end if;
    end process;

    timproc : process(CLK, RST)
        variable cen, old : std_logic;
    begin
        if RST = '1' then
            tima <= X"dd";      -- Don't initialize to zero
            INT <= '0';
        elsif rising_edge(CLK) then
            INT <= '0';
            case tac(1 downto 0) is
                when "00" => cen := clkgen(9);     -- CLK / 2^10
                when "01" => cen := clkgen(3);     -- CLK / 2^4
                when "10" => cen := clkgen(5);     -- CLK / 2^6
                when "11" => cen := clkgen(7);     -- CLK / 2^8
                when others => null;
            end case;
            if WR_EN = '1' and ABUS = X"FF05" then
                tima <= WR_D;
            elsif tac(2) = '1' and cen = '1' and old = '0' then
                -- 'tima' does not overflow to zero but is reset from 'tma' instead
                if tima = X"FF" then
                    tima <= tma;
                    INT <= '1';
                else
                    tima <= tima + "1";
                end if;
            end if;
            old := cen;
        end if;
    end process;

end Behaviour;
