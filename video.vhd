library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- FIXME: How does starting, stopping and changing the video affect
--  the phase of the clock divider, if at all?

entity video is
    Port (  DIN     : in std_logic_vector(7 downto 0);
            DOUT    : out std_logic_vector(7 downto 0);
            ABUS    : in std_logic_vector(15 downto 0);
            WR_EN   : in std_logic;
            CLK     : in std_logic;
            RST     : in std_logic );
end video;

architecture Behaviour of video is

    -- Registers
    signal lcdc, scy, scx, ly, lyc, dma, bgp, obp0, obp1, wy, wx : std_logic_vector(7 downto 0);
    signal lx : std_logic_vector(4 downto 0);

    signal mode : std_logic_vector(1 downto 0);
    signal count : std_logic_vector(8 downto 0);

    signal bgshift : std_logic_vector(7 downto 0);  -- ly - scy
    signal mapaddr : std_logic_vector(9 downto 0);  -- Address within tile map (000h -- 3FFh)
    signal dataddr : std_logic_vector(11 downto 0); -- Address in tile data table (16-bit words)
    signal tilerow : std_logic_vector(15 downto 0); -- one row of 2-bit values, 8 lsbits then 8 msbits
    signal tileidx : std_logic_vector(7 downto 0);  -- active tile

    type STATE_TYPE is (RESET, OAMSCAN, MAPREAD, TILEREAD, WAI, HBLANK, VBLANK);
    signal CS, NS: STATE_TYPE;

begin

    DOUT <= lcdc when ABUS = "1111111101000000" else     -- FF41
            "000000" & mode when ABUS = "1111111101000001" else     -- FF41
            scy  when ABUS = "1111111101000010" else
            scx  when ABUS = "1111111101000011" else
            ly   when ABUS = "1111111101000100" else
            lyc  when ABUS = "1111111101000101" else
            dma  when ABUS = "1111111101000110" else
            bgp  when ABUS = "1111111101000111" else
            obp0 when ABUS = "1111111101001000" else
            obp1 when ABUS = "1111111101001001" else
            wy   when ABUS = "1111111101001010" else
            wx   when ABUS = "1111111101001011" else
            "ZZZZZZZZ";

    bgshift <= ly + not scy + "1";
    mapaddr <= bgshift(7 downto 3) & lx;

    tileidx <= "00000000";                      -- Read from tile map

    dataddr(11) <= lcdc(3);                     -- This depends on whether background or window is being drawn
    dataddr(10 downto 3) <= tileidx;
    dataddr(2 downto 0) <= bgshift(2 downto 0);

    inproc : process(CLK, RST)
    begin
        if RST = '1' then
            lcdc <= X"7d";
            scy  <= X"03";
            scx  <= X"dd";
            lyc  <= X"dd";
            dma  <= X"dd";
            bgp  <= X"dd";
            obp0 <= X"dd";
            obp1 <= X"dd";
            wy   <= X"dd";
            wx   <= X"dd";
        elsif rising_edge(CLK) then
            if WR_EN = '1' and ABUS(15 downto 4) = "111111110100" then
                case ABUS(3 downto 0) is
                    when "0000" => lcdc <= DIN;
                    when "0010" => scy  <= DIN;
                    when "0011" => scx  <= DIN;
                    when "0101" => lyc  <= DIN;
                    when "0110" => dma  <= DIN;
                    when "0111" => bgp  <= DIN;
                    when "1000" => obp0 <= DIN;
                    when "1001" => obp1 <= DIN;
                    when "1010" => wy   <= DIN;
                    when "1011" => wx   <= DIN;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    countproc : process(CLK, RST)
    begin
        if RST = '1' then
            count <= "000000000";
        elsif rising_edge(CLK) then
            if CS = RESET then
                count <= "000000000";
            elsif count = "111000111" then
                count <= "000000000";
            else
                count <= count + "1";
            end if;
        end if;
    end process;

    lineproc : process(CLK, RST)
    begin
        if RST = '1' then
            ly <= X"00";
        elsif rising_edge(CLK) then
            if count = "111000111" then
                if ly = "10011001" then
                    ly <= "00000000";
                else
                    ly <= ly + "1";
                end if;
            end if;
        end if;
    end process;

    SYNC_PROC: process (CLK, RST)
    begin
        if RST = '1' then
            CS <= RESET;
            lx <= "00000";
        elsif falling_edge(CLK) then
            CS <= NS;
            if NS = MAPREAD then
                if CS = TILEREAD then
                    lx <= lx + "1";
                else
                    lx <= "00000";
                end if;
            elsif CS = RESET then
                lx <= "00000";
            end if;
        end if;
    end process;

    COMB_PROC: process (RST, CS, lcdc, lx, ly, count)
    begin

        case CS is
            when RESET =>
                NS <= RESET;
                if lcdc(7) = '1' then
                    NS <= OAMSCAN;
                end if;

            when OAMSCAN =>
                NS <= OAMSCAN;
                if count = "001001111" then -- 79 (4Fh)
                    NS <= MAPREAD;
                end if;

            when MAPREAD =>
                NS <= TILEREAD;

            when TILEREAD =>
                NS <= MAPREAD;
                if lx = "10011" then    -- 19 (13h)
                    NS <= WAI;
                end if;

            when WAI =>
                NS <= WAI;
                if count = "011111011" then -- 251 (FBh)
                    NS <= HBLANK;
                end if;

            when HBLANK =>
                NS <= HBLANK;
                if count = "111000111" then -- 455 (1C7h)
                    if ly = "10001111" then -- 143 (8Fh)
                        NS <= VBLANK;
                    else
                        NS <= OAMSCAN;
                    end if;
                end if;

            when VBLANK =>
                NS <= VBLANK;
                if count = "111000111" and ly = "10011001" then -- 455, 153 (1C7h, 99h)
                    NS <= OAMSCAN;
                end if;

            when others => 
                NS <= RESET;
        end case;
    end process;

end Behaviour;
