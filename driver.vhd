library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.video_comp.pixelpipe;

package driver_comp is
    component driver
    Port (  VSYNC   : out std_logic;
            HSYNC   : out std_logic;
            RED     : out std_logic_vector(2 downto 0);
            GREEN   : out std_logic_vector(2 downto 0);
            BLUE    : out std_logic_vector(1 downto 0);
            PX      : in pixelpipe;
            LOGICLK : in std_logic;
            SYSCLK  : in std_logic;
            EXTCLK  : in std_logic;
            RST     : in std_logic;
            debug : out std_logic );
    end component;

end package;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.video_comp.all;
use work.types_comp.all;

-- FIXME: How does starting, stopping and changing the driver affect
--  the phase of the clock divider, if at all?

entity driver is
    Port (  VSYNC   : out std_logic;
            HSYNC   : out std_logic;
            RED     : out std_logic_vector(2 downto 0);
            GREEN   : out std_logic_vector(2 downto 0);
            BLUE    : out std_logic_vector(1 downto 0);
            PX      : in pixelpipe;
            LOGICLK : in std_logic;
            SYSCLK  : in std_logic;
            EXTCLK  : in std_logic;
            RST     : in std_logic;
            debug : out std_logic );
end driver;

architecture Behaviour of driver is

    signal clkgen : std_logic_vector(1 downto 0);

    signal pixclk, lineclk : std_logic;
    signal linecount, framecount : unsigned(9 downto 0);
    signal gblx, gbly : std_logic_vector(9 downto 0);

    signal vblank, hblank, visible : std_logic;
    signal gblines, gbcols, gbvis : std_logic;

    signal divx, divy : std_logic_vector(1 downto 0);

    signal fb_addr : std_logic_vector(9 downto 0);
    signal pixelblk : std_logic_vector(17 downto 0);
    signal pixel : std_logic_vector(1 downto 0);

    type ONEPIXEL is array (1 downto 0) of std_logic_vector(1 downto 0);
    type readpx_regs is record
        sync_px : ONEPIXEL;
        sync_wr : std_logic_vector(1 downto 0);
        sync_clk : std_logic_vector(2 downto 0);
        rowcount : unsigned(7 downto 0);  -- which pixel in the row
        colcount : unsigned(7 downto 0);
        latch : std_logic_vector(17 downto 0);
        change : std_logic;
    end record;
    signal readpx, readpx_new : readpx_regs;

    constant ram_in_zero : ram_in := (X"00000000", "0000", "00000000000000", "0000");
    signal ain, bin, bin_new, din, din_new, fin, fin_new : ram_in;
    signal aout, bout, cout, dout, eout, fout : ram_out;

    signal toggle : std_logic;

    -- Standard timings: H 640 16 96 48 (280h 10h 60h 30h)
    --                   V 480 10 2 33 (1E0h Ah 2h 21h)
    -- visible, blank [front, sync, back]

    -- Horizontal Timing: 640   9  96  52 (280h   9h  60h  34h)
    --                    640 649 745 797 (280h 289h 2E9h 31Dh)
    -- Vertical Timing: 480  10   2  33 (1E0h   Ah   2h  21h)
    --                  480 490 492 525 (1E0h 1EAh 1ECh 20Dh)
    -- With a 25 MHz pixel clock this gives a refresh rate of 59.748 Hz

    -- SVGA Timing: 800 840 968 1056 (320h 348h 3C8h 420h)
    --              600 601 605  628 (258h 259h 25Dh 274h)
    -- 60.3165 Hz at 40 MHz pixel clock

    type timing is record
        vis   : unsigned(11 downto 0);
        front : unsigned(11 downto 0);
        sync  : unsigned(11 downto 0);
        back  : unsigned(11 downto 0);
        half  : unsigned(11 downto 0);
    end record;
--  constant hori : timing := (X"280", X"010", X"060", X"030", X"190");
--  constant vert : timing := (X"1E0", X"00A", X"002", X"021", X"000");
    constant hori : timing := (X"320", X"028", X"080", X"058", X"210");
    constant vert : timing := (X"258", X"001", X"004", X"017", X"000");

    type bbox is record
        lo,hi : unsigned(11 downto 0);
    end record;
    constant gbhori : bbox := (X"050", X"230");
    constant gbvert : bbox := (X"018", X"1C8");

    signal pause : unsigned(1 downto 0);

begin

    process(RST,SYSCLK)
    begin
        if RST = '1' then
            toggle <= '0';
        elsif falling_edge(SYSCLK) then
            toggle <= not(toggle);
        end if;
    end process;

    process(px, readpx, bin, din, fin, bout, dout, fout, toggle)
        variable nxtpx : readpx_regs;
        variable nxtbin, nxtdin, nxtfin : ram_in;
        variable edge : std_logic;
        variable newpx : std_logic_vector(1 downto 0);
    begin
        nxtpx := readpx;
        nxtbin := bin;
        nxtdin := din;
        nxtfin := fin;

        nxtpx.sync_px(1) := PX.px;
        nxtpx.sync_px(0) := readpx.sync_px(1);
        nxtpx.sync_wr := PX.wr & readpx.sync_wr(1);
        nxtpx.sync_clk := toggle & readpx.sync_clk(2 downto 1);

        if readpx.sync_clk(0) /= readpx.sync_clk(1) then
            edge := '1';
        else
            edge := '0';
        end if;

        -- FIXME Enormous degree of code duplication due to 3 blockrams
        nxtbin.ipar(1 downto 0) := bout.opar(1 downto 0);
        nxtbin.idata(15 downto 0) := bout.odata(15 downto 0);
        nxtdin.ipar(1 downto 0) := dout.opar(1 downto 0);
        nxtdin.idata(15 downto 0) := dout.odata(15 downto 0);
        nxtfin.ipar(1 downto 0) := fout.opar(1 downto 0);
        nxtfin.idata(15 downto 0) := fout.odata(15 downto 0);

        newpx := readpx.sync_px(0);

        if readpx.rowcount(7 downto 4) = "0000" then
            nxtbin.idata(1 downto 0) := newpx;
            nxtdin.idata(1 downto 0) := newpx;
            nxtfin.idata(1 downto 0) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0001" then
            nxtbin.idata(3 downto 2) := newpx;
            nxtdin.idata(3 downto 2) := newpx;
            nxtfin.idata(3 downto 2) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0010" then
            nxtbin.idata(5 downto 4) := newpx;
            nxtdin.idata(5 downto 4) := newpx;
            nxtfin.idata(5 downto 4) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0011" then
            nxtbin.idata(7 downto 6) := newpx;
            nxtdin.idata(7 downto 6) := newpx;
            nxtfin.idata(7 downto 6) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0100" then
            nxtbin.idata(9 downto 8) := newpx;
            nxtdin.idata(9 downto 8) := newpx;
            nxtfin.idata(9 downto 8) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0101" then
            nxtbin.idata(11 downto 10) := newpx;
            nxtdin.idata(11 downto 10) := newpx;
            nxtfin.idata(11 downto 10) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0110" then
            nxtbin.idata(13 downto 12) := newpx;
            nxtdin.idata(13 downto 12) := newpx;
            nxtfin.idata(13 downto 12) := newpx;
        elsif readpx.rowcount(7 downto 4) = "0111" then
            nxtbin.idata(15 downto 14) := newpx;
            nxtdin.idata(15 downto 14) := newpx;
            nxtfin.idata(15 downto 14) := newpx;
        elsif readpx.rowcount(7 downto 4) = "1000" then
            nxtbin.ipar(1 downto 0) := newpx;
            nxtdin.ipar(1 downto 0) := newpx;
            nxtfin.ipar(1 downto 0) := newpx;
        end if;

        if readpx.sync_wr(0) = '1' and edge = '1' then
            nxtpx.change := '1';

            if nxtpx.colcount(7 downto 6) = "00" then
                nxtbin.wen := (others => '1');
            elsif nxtpx.colcount(7 downto 6) = "01" then
                nxtdin.wen := (others => '1');
            elsif nxtpx.colcount(7 downto 6) = "10" then
                nxtfin.wen := (others => '1');
            end if;

            if readpx.colcount = X"9F" then
                nxtpx.colcount := X"00";
                if readpx.rowcount = X"8F" then
                    nxtpx.rowcount := X"00";
                else
                    nxtpx.rowcount := readpx.rowcount + "1";
                end if;
            else
                nxtpx.colcount := readpx.colcount + "1";
            end if;
        else
            nxtpx.change := '0';
            nxtbin.wen := (others => '0');
            nxtdin.wen := (others => '0');
            nxtfin.wen := (others => '0');
        end if;

        if readpx.change = '1' then
            nxtbin.addr(13 downto 8) := std_logic_vector(nxtpx.colcount(5 downto 0));
            nxtbin.addr(7 downto 4) := std_logic_vector(nxtpx.rowcount(3 downto 0));
            nxtdin.addr := nxtbin.addr;
            nxtfin.addr := nxtbin.addr;
        end if;

        bin_new <= nxtbin;
        din_new <= nxtdin;
        fin_new <= nxtfin;
        readpx_new <= nxtpx;
    end process;

    process(RST,pixclk)
    begin
        if RST = '1' then
            readpx.sync_px <= (others => (others => '0'));
            readpx.sync_wr <= (others => '0');
            readpx.sync_clk <= (others => '0');
            readpx.rowcount <= (others => '0');
            readpx.colcount <= (others => '0');
            readpx.latch <= (others => '0');
            readpx.change <= '0';
            bin <= ram_in_zero;
            din <= ram_in_zero;
            fin <= ram_in_zero;
            pause <= (others => '0');
            debug <= '0';
        elsif rising_edge(pixclk) then
            bin <= bin_new;
            din <= din_new;
            fin <= fin_new;
            readpx <= readpx_new;
            pause <= pause + "1";
            if PX.wr = '1' then
                debug <= '1';
            end if;
        end if;
    end process;



    -- Divide 100 MHz system clock by 4
    clkproc : process(LOGICLK, RST)
    begin
        if RST = '1' then
            clkgen <= "00";
        elsif rising_edge(LOGICLK) then
            clkgen <= clkgen + "1";
        end if;
    end process;

--  pixclk <= clkgen(1);
--  upixclk : BUFG port map ( I => clkgen(1), O => pixclk );
    pixclk <= EXTCLK;

    -- 'linecount' incrementer clocked by 'pixelclock'
    process(pixclk, RST)
    begin
        if RST = '1' then
            linecount <= "0000000000";
        elsif falling_edge(pixclk) then
            if linecount = (hori.vis + hori.front + hori.sync + hori.back - "1") then
                linecount <= "0000000000";
            else
                linecount <= linecount + "1";
            end if;
        end if;
    end process;

    -- 'framecount' incrementer clocked by 'lineclk'
    process(pixclk, RST)
        variable old : std_logic;
    begin
        if RST = '1' then
            framecount <= "0000000000";
        elsif rising_edge(pixclk) then
            if old = '1' and lineclk = '0' then
                if framecount = (vert.vis + vert.front + vert.sync + vert.back - "1") then
                    framecount <= "0000000000";
                else
                    framecount <= framecount + "1";
                end if;
            end if;
            old := lineclk;
        end if;
    end process;

    lineclk <= '0' when linecount < hori.half else '1';

    HSYNC  <= '1' when linecount < hori.vis + hori.front else
              '0' when linecount < hori.vis + hori.front + hori.sync else '1';
    hblank <= '0' when linecount < hori.vis else '1';

    VSYNC  <= '1' when framecount < vert.vis + vert.front else
              '0' when framecount < vert.vis + vert.front + vert.sync else '1';
    vblank <= '0' when framecount < vert.vis else '1';

    gbcols <= '0' when linecount < gbhori.lo else
              '1' when linecount < gbhori.hi else '0';
    gblines <= '0' when framecount < gbvert.lo else
               '1' when framecount < gbvert.hi else '0';
    gbvis <= gblines and gbcols;

    visible <= (hblank nor vblank);

    -- Create 'gblx' clock, as (linecount - gbhori.lo) / 3
    divxproc : process(RST, pixclk)
    begin
        if RST = '1' then
            divx <= "00";
            gblx <= "0000000000";
        elsif falling_edge(pixclk) then
            if linecount = (gbhori.lo - "1") then
                divx <= "00";
                gblx <= "0000000000";
            elsif divx = "10" then
                divx <= "00";
                gblx <= gblx + "1";
            else
                divx <= divx + "1";
            end if;
        end if;
    end process;

    -- Create 'gbly' clock, as (framecount - gbvert.lo) / 3
    divyproc : process(RST, pixclk)
        variable old : std_logic;
    begin
        if RST = '1' then
            divy <= "00";
            gbly <= "0000000000";
        elsif rising_edge(pixclk) then
            if old = '1' and lineclk = '0' then
                if framecount = (gbvert.lo - "1") then
                    divy <= "00";
                    gbly <= "0000000000";
                elsif divy = "10" then
                    divy <= "00";
                    gbly <= gbly + "1";
                else
                    divy <= divy + "1";
                end if;
            end if;
            old := lineclk;
        end if;
    end process;

    colors : process(RST, visible, gbvis, framecount, linecount, gblx, gbly, pixel)
        variable shift : std_logic_vector(9 downto 0);
    begin
        if RST = '1' then
            RED <= "000";
            GREEN <= "000";
            BLUE <= "00";
        elsif gbvis = '1' then
            if pixel = "00" then  -- white
                RED <= "111";
                GREEN <= "111";
                BLUE <= "11";
            elsif pixel = "01" then  -- light grey
                RED <= "100";
                GREEN <= "100";
                BLUE <= "10";
            elsif pixel = "10" then  -- dark grey
                RED <= "010";
                GREEN <= "010";
                BLUE <= "01";
            else  -- black
                RED <= "000";
                GREEN <= "000";
                BLUE <= "00";
            end if;
        elsif visible = '1' then
            RED   <= std_logic_vector(linecount(3 downto 1));
            GREEN <= std_logic_vector(framecount(3 downto 1));
            BLUE  <= std_logic(framecount(4)) & std_logic(linecount(4));
        else
            RED <= "000";
            GREEN <= "000";
            BLUE <= "00";
        end if;
    end process;

    -- Address for framebuffer is set according to 'gblx' and 'gbly'
    ain.addr(13 downto 4) <= gblx(5 downto 0) & gbly(3 downto 0);
    ain.addr(3 downto 0) <= X"0";

    -- Blocks of 9 pixels read at once
    with gblx(7 downto 6) select
        pixelblk <= aout.opar(1 downto 0) & aout.odata(15 downto 0) when "00",
                    cout.opar(1 downto 0) & cout.odata(15 downto 0) when "01",
                    eout.opar(1 downto 0) & eout.odata(15 downto 0) when "10",
                    (others => '0') when others;
    with gbly(7 downto 4) select
        pixel <= pixelblk(1 downto 0) when X"0",
                 pixelblk(3 downto 2) when X"1",
                 pixelblk(5 downto 4) when X"2",
                 pixelblk(7 downto 6) when X"3",
                 pixelblk(9 downto 8) when X"4",
                 pixelblk(11 downto 10) when X"5",
                 pixelblk(13 downto 12) when X"6",
                 pixelblk(15 downto 14) when X"7",
                 pixelblk(17 downto 16) when X"8",
       "00" when others;

    ain.idata <= (others => '0');
    ain.ipar <= (others => '0');


    -- Framebuffer containing 64 columns of 144 rows
    frame00 : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 18,
        DATA_WIDTH_B => 18,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
--      INIT_00 => X"5000500050005000500050005000600050004000400040008000400040004000",
--      INIT_01 => X"6000500050009000500050005000A00070005000500040004000400040004000",
--      INIT_02 => X"5000900050006000500060005000600060005000600090004000400080004000",
--      INIT_03 => X"5300520053005200510060009400EC00AC0098009C00AC009C004C0048005800",
--      INIT_04 => X"53009300A300BF009F00AF00AF005E00AF009F009E0099007C00AC004C004C00",
--      INIT_05 => X"9300A700AF009F00BF006F009F009B009F009F009F005F006F004A004D004C00",
--      INIT_06 => X"B6C097C0AE809F009A00AF009E009F009E009F005E00AB004E004F004F008B00",
--      INIT_07 => X"93C0A7C09FC0AFC09FC09F409F009F005F005B006F004F004F004B008F00AE00",
--      INIT_08 => X"53C09FC0AFC09F809FC09F80DB809FC09FC05F804F404F008F005F008F008F00",
--      INIT_09 => X"6BD05FC05FC05BC09FC05FC05FC06FC05FC04FC08F808FC09F80CFC08FC08F80",
--      INIT_0A => X"5BE05FF06BF05FE05FD05FC05FC05FC04FC04F804FC05FC04FC04FC04F808FC0",
--      INIT_0B => X"6BF05FF05FE09FF05FE05FF06FE08FF04FF08FD06FC04FC04F804FC06FC07FC0",
--      INIT_0C => X"9FE05FF09FF05FF05FF06FF08FF04FF04FE05FF05FE04FC04FC08FC07F807FC0",
--      INIT_0D => X"6FF05FF05FE06FF15FE26FE04FF04FE25FF04FF04FF08FF04FF07FE07FD06FC0",
--      INIT_0E => X"5FF45FF05FF05FF05FF29FF14FF05FF29FE04FF24FE04FF27FF07FF0BFE07FF0",
--      INIT_0F => X"5F785F746B3097705370537247B15FB24FB04FF24FF14FF2BFE07FF07FF07EE0",
--      INIT_10 => X"A33D533AA37A53326332633253329B334F204F738F707F627CB05C704CA04CF0",
--      INIT_11 => X"5379533A6339433643319333637143325FB04FF24FE07DF24CF04CE08DB04C70",
--      INIT_12 => X"532C53294378433A437843724330433357B28DF34CF24CF38CE14CF04CF04CE0",
--      INIT_13 => X"533C633D8318431A9328533A53318332513044324C314D324C314D304C204DB0",
--      INIT_14 => X"A32C63794338435A5318533B63345232603341324C308C324C304C308C304C30",
--      INIT_15 => X"5348430E433D533A4329435A431E40364470843244714DF24CF04DF04CF04C30",
--      INIT_16 => X"A31D430E531A937B433A832A453B8D1A44304532403048F24CF08CF04DF04CF0",
--      INIT_17 => X"637C473C574C4718473841BB407C40FE483044328031417240F04CF04CF08CE0",
--      INIT_18 => X"4B3C4338833C4319473A4098449881FE40384130483044F241F08CE0ADF09CF0",
--      INIT_19 => X"477C573C437C4338423A8058408C40DE44AC4430407048F098F09CF08CF08CF0",
--      INIT_1A => X"4538A13C413C473840784458419C40C841DC60E0A1F094F095F084F081F004F0",
--      INIT_1B => X"447C553C4238423C40388018404854CC60CC90D494E090F094F094F084F014F0",
--      INIT_1C => X"553C413D457D407D65396119540D515D90C995CD54E294E195E080F095F014F0",
--      INIT_1D => X"E17CE23DD03AD02DD039D079D039903ED02DA42DD0E595D280D0C4D004F040F0",
--      INIT_1E => X"613CA63CA17EE43C9108D438D03CE17ED438D53C94385472147054A045A0D4F0",
--      INIT_1F => X"F24CA00CE40ED00CA058E008A048D53AD03CD47CD039A5328030C52040704430",
--      INIT_20 => X"D60CE11CA04EA00CA108A408A11CA00EA52C6438543C54729430843044300420",
--      INIT_21 => X"419C5008440E811C54486008A14C610A654C601C655D64325130447090301530",
--      INIT_22 => X"418C504C400E4008401840086118650E541C5408640CA0024470443095301570",
--      INIT_23 => X"424C950E401E854E400A414A440E404F510AA44E650E64124500540040701430",
--      INIT_24 => X"4508411C400C400C40184408401C8008441C440C401870404400800044105410",
--      INIT_25 => X"4114410C554C400C45484008814C400C4508444C450C84005550541045409500",
--      INIT_26 => X"510442449004501C400840184408401C444C801C440844004400400054006000",
--      INIT_27 => X"A91046004014510840488108404C410C4408450C444C41104440850044404400",
--      INIT_28 => X"5244434C440C444844184408401C4018801C402C4C1848104C104C104D105C10",
--      INIT_29 => X"531C570C811C44089008550C8408490C548C4548804C45008C104C208C704C20",
--      INIT_2A => X"570C5308420C41084008409C440C581850CC40CC44DC4CA04C704D304C304D30",
--      INIT_2B => X"533C935C471C458840C85518402C513D843C4DF84CFC4DF04CF04CF04CF04C70",
--      INIT_2C => X"533C6738432C4398A4F9603C843C503A4C3C4CFC4CFC8CF04CF08DF04CF08DF0",
--      INIT_2D => X"531E533DA39C538A51CE51D8441C5D2E5CFC5DFC4CF04DF04CF04CF04CF04CF0",
--      INIT_2E => X"533B537E57D857C857DC44CE4CCE4CC95CDEBCCA7CD2BCD24DE04CF04DF04CF0",
--      INIT_2F => X"632E937E535853C843C88CCA4CDE8DCE4CEE7DD77CF27CF27CF06CF08CE04CF0",
--      INIT_30 => X"5F595F3A5B086B5A8FCE4FDC4DEC6CFE4CFC7CE0BCF07DE07CF07CE07DF07CF0",
--      INIT_31 => X"5F3C5F3A9F185F0A5FAE4FFD4FFC5CBE5CFC5DF07CF17CF17CF1ADF07CF06CF0",
--      INIT_32 => X"9B7C6F385B3B5F386F3D5F3D4FBD4DBE5DF18CF15CF37DF17CF17CF07CB0BC70",
--      INIT_33 => X"5E185F285F0A5F1F5B1C9B2C4F3C8B394F30A9304D32B8307C30BD70BCB07DE0",
--      INIT_34 => X"9F289F189E58AF9E9F6E9F3CAF3E8F358B309E309D738D30FC70F8F0FCF0BC60",
--      INIT_35 => X"DF389E789F389FFCDEFC9FFF9EF28FF18FF08FF09FF39BF09FF07FF07E70BA60",
--      INIT_36 => X"AFB89F78AF789FBC6FBE9FFE9FF0AFF14FF08EF04FF2BFF09FF0BFB0BFE0BFE0",
--      INIT_37 => X"DFF8BFF89FF89FFC9FFD9FF09F709FB2AFF08FF08FF09FF07FF0BFF07FE0FFE0",
--      INIT_38 => X"5FF86FF8AFF8AFFC9FF09FF09FF05FF09FF0BFF08FF08FF0AFE0BFE0BFE07FE0",
--      INIT_39 => X"AFF86FF86FF86FF09FF09FF0DFF0AFF09FF06FF06FF04FF08FE0BFE07FE0BFE0",
--      INIT_3A => X"5FF85FF85FF06FF05FF07FF05FF06FF06FF0AFF0AFF09FE0BFE07FE07FE07FE0",
--      INIT_3B => X"5FF85FF05FF09FF07FF05FF06FF06FF06FF06FF07FE06FE09FE07FE07FE0BFE0",
--      INIT_3C => X"9FF09FF06FF05FF05FF05FF06FF06FF06FF04FE04FE04FE04FE04FE07FE07FC0",
--      INIT_3D => X"AFF09FF09FF09FF09FF09FF09FF08FF08FE08FE08FE08FF04FC08FC08FC09FC0",
--      INIT_3E => X"A3F06FF0AFF0AFF0AFF09FF08FF08FE04FF08FD08FD04FC08FC08FC08FC08FC0",
--      INIT_3F => X"83E083D083D087D08BC08FC08FC08FC04FC04FC00F800F800F800F800F800F80",
--      INITP_00 => X"FF104415FF6AA955FF9AAA69FFDA6AAAFFDAA6A6FFFAAAAAFFFA69A6FFF6AAAA",
--      INITP_01 => X"FDAAAAAAFD9A6AA6FDAAA6AAFDA6AA6AFDAA6A9AFEAAA6A9FFA6AAAAFFAAAAAA",
--      INITP_02 => X"FAA56566FAA9556AFAAA596AFEAA956AFE69955AFEAAA969FDAAA96AFE666A5A",
--      INITP_03 => X"F9445040F5555569F0000000F555666AF655556AFA99556AFA555966F6A6556A",
--      INITP_04 => X"FD55569AFE6595AAFD5565A9FD65556AFD56595AFA555569F995966AF8040001",
--      INITP_05 => X"FD99556AFD5559AAFC665599FD5566AAFD5555AAFD9956A6FD5665A9FD5556AA",
--      INITP_06 => X"FFEAAA90FF845115FFD55555FF156555FF555556FF59595AFF55566AFE559569",
--      INITP_07 => X"FFFD5555FFFC5555FFF99999FFF95555FFF5655AFFF155AAFFF5A99AFFF6AAAA",
        INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        WRITE_MODE_B => "READ_FIRST",  -- To allow A to read from this address while B is writing
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => aout.odata,-- 32-bit output: A port data output
        DOPA => aout.opar,-- 4-bit output: A port parity output
        ADDRA => ain.addr, -- 14-bit input: A port address input
        CLKA => pixclk,  -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => ain.idata, -- 32-bit input: A port data input
        DIPA => ain.ipar, -- 4-bit input: A port parity input
        -- Port B
        DOB => bout.odata,-- 32-bit output: A port data output
        DOPB => bout.opar,-- 4-bit output: A port parity output
        ADDRB => bin.addr,-- 14-bit input: B port address input
        CLKB => pixclk,  -- 1-bit input: B port clock input
        ENB => '1',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => bin.wen,   -- 4-bit input: Port B byte-wide write enable input
        DIB => bin.idata, -- 32-bit input: B port data input
        DIPB => bin.ipar  -- 4-bit input: B port parity input
    );

    -- Framebuffer containing 64 columns of 144 rows
    frame64 : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 18,
        DATA_WIDTH_B => 18,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        WRITE_MODE_B => "READ_FIRST",  -- To allow A to read from this address while B is writing
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => cout.odata,-- 32-bit output: A port data output
        DOPA => cout.opar,-- 4-bit output: A port parity output
        ADDRA => ain.addr, -- 14-bit input: A port address input
        CLKA => pixclk,  -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => ain.idata, -- 32-bit input: A port data input
        DIPA => ain.ipar, -- 4-bit input: A port parity input
        -- Port B
        DOB => dout.odata,-- 32-bit output: A port data output
        DOPB => dout.opar,-- 4-bit output: A port parity output
        ADDRB => din.addr,-- 14-bit input: B port address input
        CLKB => pixclk,  -- 1-bit input: B port clock input
        ENB => '1',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => din.wen,   -- 4-bit input: Port B byte-wide write enable input
        DIB => din.idata, -- 32-bit input: B port data input
        DIPB => din.ipar  -- 4-bit input: B port parity input
    );

    -- Framebuffer containing 64 columns of 144 rows
    frame128 : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 18,
        DATA_WIDTH_B => 18,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        WRITE_MODE_B => "READ_FIRST",  -- To allow A to read from this address while B is writing
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => eout.odata,-- 32-bit output: A port data output
        DOPA => eout.opar,-- 4-bit output: A port parity output
        ADDRA => ain.addr, -- 14-bit input: A port address input
        CLKA => pixclk,  -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => ain.idata, -- 32-bit input: A port data input
        DIPA => ain.ipar, -- 4-bit input: A port parity input
        -- Port B
        DOB => fout.odata,-- 32-bit output: A port data output
        DOPB => fout.opar,-- 4-bit output: A port parity output
        ADDRB => fin.addr,-- 14-bit input: B port address input
        CLKB => pixclk,  -- 1-bit input: B port clock input
        ENB => '1',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => fin.wen,   -- 4-bit input: Port B byte-wide write enable input
        DIB => fin.idata, -- 32-bit input: B port data input
        DIPB => fin.ipar  -- 4-bit input: B port parity input
    );
end Behaviour;
