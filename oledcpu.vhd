library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

library UNISIM;
use UNISIM.VComponents.all;

entity oledcpu is
    Port (
        CS : out  STD_LOGIC;
        SDIN : out  STD_LOGIC;
        SCLK : out  STD_LOGIC;
        DATA : out  STD_LOGIC;
        RES : out  STD_LOGIC;
        VDD : out STD_LOGIC;
        VBAT : out STD_LOGIC;
        RST : IN STD_LOGIC;
        CLK : in  STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR(7 downto 0);
        SW : IN STD_LOGIC_VECTOR(3 downto 0);
        BTN : IN STD_LOGIC_VECTOR(4 downto 0) );
end oledcpu;

architecture Behavioral of oledcpu is

    component debouncer
        Port (
            rst : in std_logic;
            btn : in  STD_LOGIC;
            clk : in  STD_LOGIC;
            filtered : out  STD_LOGIC);
    end component;

    signal RAMA : std_logic_vector(31 downto 0);
    signal ADDRA : std_logic_vector(9 downto 0);
    signal RAMB : std_logic_vector(31 downto 0);

    signal tcol : std_logic_vector(6 downto 0);   -- pixel column counter
    signal trow : std_logic_vector(2 downto 0);   -- pixel row counter
    signal tchar : std_logic_vector(4 downto 0);  -- character counter
    signal tbyte : std_logic_vector(2 downto 0);  -- character column counter

    signal clkdiv : std_logic;
    signal divtimer : std_logic_vector(3 downto 0);
    signal medtimer : std_logic_vector(4 downto 0);
    signal slowtimer : std_logic_vector(31 downto 0);
    signal sclken : std_logic;

    signal txdata : std_logic_vector(7 downto 0);
    signal txbuf : std_logic_vector(7 downto 0);
    signal txbit : std_logic_vector(3 downto 0);
    signal txdone : std_logic;
    signal txgo : std_logic;
    signal state : std_logic_vector(2 downto 0);

    signal pol, spol : std_logic;

    signal pwr : std_logic;

    signal ptimer : std_logic;
    signal itimer : std_logic_vector(23 downto 0);

    signal rsttimer : std_logic_vector(27 downto 0);

    signal btnu : std_logic;
    signal btnd : std_logic;
    signal btnm : std_logic;

    signal addr : std_logic_vector(1 downto 0);
    signal row : std_logic_vector(19 downto 0);

    signal digit : std_logic_vector(7 downto 0);
    signal d_en : std_logic;

    signal cpu_addr : std_logic_vector(15 downto 0);
    signal cpu_cmd : std_logic_vector(7 downto 0);
    signal cpu_acc : std_logic_vector(7 downto 0);
    signal cpu_flag : std_logic_vector(3 downto 0);
    signal cpu_mop : std_logic_vector(53 downto 0);
    signal cpu_pc, cpu_sp, cpu_bc, cpu_de, cpu_hl : std_logic_vector(15 downto 0);

    -- GBCPU
    COMPONENT microcode
        Port (  ABUS : buffer STD_LOGIC_VECTOR(15 downto 0);
                RAM : in STD_LOGIC_VECTOR(7 downto 0);
                RAM_OE : out STD_LOGIC;
                WR_D : out std_logic_vector(7 downto 0);
                RAM_WR : out std_logic;
                CLK : IN STD_LOGIC;
                CLK90 : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    END COMPONENT;

    signal ADDRCPU : STD_LOGIC_VECTOR(13 downto 0);
    signal ABUS : STD_LOGIC_VECTOR(15 downto 0);
    signal RAM : STD_LOGIC_VECTOR(7 downto 0);
    signal DOA_CART   : STD_LOGIC_VECTOR(31 downto 0);  -- A port data output

begin

    cpu_addr <= ABUS;
    cpu_cmd <= X"00";
    cpu_acc <= X"01";
    cpu_flag <= X"1";
    cpu_mop <= "10" & X"0000000000000";
    cpu_pc <= X"44FD";
    cpu_sp <= X"8a20";
    cpu_bc <= X"b00b";
    cpu_de <= X"b00b";
    cpu_hl <= X"b00b";

    -- RAMB16BWER: 16k-bit Data and 2k-bit Parity Configurable Synchronous Dual Port Block RAM with Optional Output Registers
    --       Spartan-6
    -- Xilinx HDL Language Template, version 13.3

    fontram : RAMB16BWER
    generic map (
        -- DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        -- DOA_REG/DOB_REG: Optional output register (0 or 1)
        DOA_REG => 0,
        DOB_REG => 0,
        -- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- INIT_00 to INIT_3F: Initial memory contents.
        INIT_00 => X"147F147F14000000000700070000000000005F00000000000000000000000000", -- 000
        INIT_01 => X"000503000000000036495522500000002313086462000000242A7F2A12000000",
        INIT_02 => X"08083E0808000000082A1C2A080000000041221C00000000001C224100000000",
        INIT_03 => X"2010080402000000006060000000000008080808080000000050300000000000",
        INIT_04 => X"2141454B31000000426151494600000000427F40000000003E5149453E000000",
        INIT_05 => X"01710905030000003C4A49493000000027454545390000001814127F10000000",
        INIT_06 => X"00563600000000000036360000000000064949291E0000003649494936000000",
        INIT_07 => X"0201510906000000412214080000000014141414140000000008142241000000",
        INIT_08 => X"3E414141220000007F494949360000007E1111117E000000324979413E000000", -- 100
        INIT_09 => X"3E414151320000007F090901010000007F494949410000007F4141221C000000",
        INIT_0a => X"7F081422410000002040413F0100000000417F41000000007F0808087F000000",
        INIT_0b => X"3E4141413E0000007F0408107F0000007F0204027F0000007F40404040000000",
        INIT_0c => X"46494949310000007F091929460000003E4151215E0000007F09090906000000",
        INIT_0d => X"7F2018207F0000001F2040201F0000003F4040403F00000001017F0101000000",
        INIT_0e => X"00007F4141000000615149454300000003047804030000006314081463000000",
        INIT_0f => X"4040404040000000040201020400000041417F00000000000204081020000000",
        INIT_10 => X"38444444200000007F4844443800000020545454780000000001020400000000", -- 200
        INIT_11 => X"081454543C000000087E0901020000003854545418000000384444487F000000",
        INIT_12 => X"007F1028440000002040443D0000000000447D40000000007F08040478000000",
        INIT_13 => X"38444444380000007C080404780000007C0418047800000000417F4000000000",
        INIT_14 => X"48545454200000007C08040408000000081414187C0000007C14141408000000",
        INIT_15 => X"3C4030403C0000001C2040201C0000003C4040207C000000043F444020000000",
        INIT_16 => X"00083641000000004464544C440000000C5050503C0000004428102844000000",
        INIT_17 => X"081C2A080800000008082A1C08000000004136080000000000007F0000000000",
        -- INIT_A/INIT_B: Initial values on output port
        INIT_A => X"000000000",
        INIT_B => X"000000000",
        -- INIT_FILE: Optional file used to specify initial RAM contents
        INIT_FILE => "NONE",
        -- RSTTYPE: "SYNC" or "ASYNC"
        RSTTYPE => "SYNC",
        -- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        -- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
        SIM_COLLISION_CHECK => "ALL",
        -- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
        SIM_DEVICE => "SPARTAN6", -- was: "SPARTAN3ADSP",
        -- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
        SRVAL_A => X"000000000",
        SRVAL_B => X"000000000",
        -- WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
        WRITE_MODE_A => "WRITE_FIRST",
        WRITE_MODE_B => "WRITE_FIRST"
    )
    port map (
        -- Port A
        DOA => RAMA,    -- 32-bit output: A port data output
        ADDRA => '0' & ADDRA & "000",  -- 14-bit input: A port address input
        CLKA => CLK,    -- 1-bit input: A port clock input
        ENA => '1',     -- 1-bit input: A port enable input
        REGCEA => '0',  -- 1-bit input: A port register clock enable input
        RSTA => '0',    -- 1-bit input: A port register set/reset input
        WEA => "0000",  -- 4-bit input: Port A byte-wide write enable input
        DIA => X"00000000", -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B
--      DOB => RAMB,   -- 32-bit output: B port data output
        ADDRB => "1000" & not trow(2 downto 1) & tchar & "000",   -- 14-bit input: B port address input
        CLKB => CLK,    -- 1-bit input: B port clock input
        ENB => '1',     -- 1-bit input: B port enable input
        REGCEB => '0',  -- 1-bit input: B port register clock enable input
        RSTB => '0',    -- 1-bit input: B port register set/reset input
        WEB => "0000",  -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000",     -- 32-bit input: B port data input
        DIPB => "0000"  -- 4-bit input: B port parity input
    );

    RAMB(7 downto 0) <= X"20" when d_en = '0' else
                        digit when digit > X"0f" else
                        digit + X"30" when digit < X"a" else
                        digit + X"57";

    process(trow, tchar, cpu_cmd, cpu_mop)
    begin
        d_en <= '1';
        digit <= X"20";
        case trow(2 downto 1) is
            when "11" =>
                case tchar is
                    when "00000" => digit <= X"0" & cpu_cmd(7 downto 4);
                    when "00001" => digit <= X"0" & cpu_cmd(3 downto 0);
                    when "00011" => digit <= X"50";
                    when "00100" => digit <= X"43";
                    when "00101" => digit <= X"3a";
                    when "00110" => digit <= X"0" & cpu_pc(15 downto 12);
                    when "00111" => digit <= X"0" & cpu_pc(11 downto 8);
                    when "01000" => digit <= X"0" & cpu_pc(7 downto 4);
                    when "01001" => digit <= X"0" & cpu_pc(3 downto 0);
                    when "01101" => digit <= X"41";
                    when "01110" => digit <= X"46";
                    when "01111" => digit <= X"3a";
                    when "10000" => digit <= X"0" & cpu_acc(7 downto 4);
                    when "10001" => digit <= X"0" & cpu_acc(3 downto 0);
                    when "10011" => digit <= X"0" & cpu_flag(3 downto 0);
                    when others => d_en <= '0';
                end case;
            when "10" =>
                case tchar is
                    when "00011" => digit <= X"53";
                    when "00100" => digit <= X"50";
                    when "00101" => digit <= X"3a";
                    when "00110" => digit <= X"0" & cpu_sp(15 downto 12);
                    when "00111" => digit <= X"0" & cpu_sp(11 downto 8);
                    when "01000" => digit <= X"0" & cpu_sp(7 downto 4);
                    when "01001" => digit <= X"0" & cpu_sp(3 downto 0);
--                  when "01101" => digit <= X"42";
--                  when "01110" => digit <= X"43";
--                  when "01111" => digit <= X"3a";
                    when "10001" => digit <= X"0" & cpu_bc(15 downto 12);
                    when "10010" => digit <= X"0" & cpu_bc(11 downto 8);
                    when "10011" => digit <= X"0" & cpu_bc(7 downto 4);
                    when "10100" => digit <= X"0" & cpu_bc(3 downto 0);
                    when others => d_en <= '0';
                end case;
            when "01" =>
                case tchar is
                    when "00000" => digit <= X"20";
                    when "00001" => digit <= X"41";
                    when "00010" => digit <= X"64";
                    when "00011" => digit <= X"64";
                    when "00100" => digit <= X"72";
                    when "00101" => digit <= X"3a";
                    when "00110" => digit <= X"0" & cpu_addr(15 downto 12);
                    when "00111" => digit <= X"0" & cpu_addr(11 downto 8);
                    when "01000" => digit <= X"0" & cpu_addr(7 downto 4);
                    when "01001" => digit <= X"0" & cpu_addr(3 downto 0);
                    when "10001" => digit <= X"0" & cpu_de(15 downto 12);
                    when "10010" => digit <= X"0" & cpu_de(11 downto 8);
                    when "10011" => digit <= X"0" & cpu_de(7 downto 4);
                    when "10100" => digit <= X"0" & cpu_de(3 downto 0);
                    when others => d_en <= '0';
                end case;
            when "00" =>
                case tchar is
                    when "00000" => digit <= "000000" & cpu_mop(53 downto 52);
                    when "00001" => digit <= X"0" & cpu_mop(51 downto 48);
                    when "00010" => digit <= X"0" & cpu_mop(47 downto 44);
                    when "00011" => digit <= X"0" & cpu_mop(43 downto 40);
                    when "00100" => digit <= X"0" & cpu_mop(39 downto 36);
                    when "00101" => digit <= X"0" & cpu_mop(35 downto 32);
                    when "00110" => digit <= X"0" & cpu_mop(31 downto 28);
                    when "00111" => digit <= X"0" & cpu_mop(27 downto 24);
                    when "01000" => digit <= X"0" & cpu_mop(23 downto 20);
                    when "01001" => digit <= X"0" & cpu_mop(19 downto 16);
                    when "01010" => digit <= X"0" & cpu_mop(15 downto 12);
                    when "01011" => digit <= X"0" & cpu_mop(11 downto 8);
                    when "01100" => digit <= X"0" & cpu_mop(7 downto 4);
                    when "01101" => digit <= X"0" & cpu_mop(3 downto 0);
                    when "10001" => digit <= X"0" & cpu_hl(15 downto 12);
                    when "10010" => digit <= X"0" & cpu_hl(11 downto 8);
                    when "10011" => digit <= X"0" & cpu_hl(7 downto 4);
                    when "10100" => digit <= X"0" & cpu_hl(3 downto 0);
                    when others => d_en <= '0';
                end case;
            when others => null;
        end case;
    end process;

    ADDRA(9 downto 3) <= RAMB(6 downto 0) - "0100000";
    ADDRA(2 downto 0) <= ("111" - tbyte);


    LED(0) <= spol;
    LED(1) <= tchar(0);
    LED(4 downto 2) <= trow;
    LED(7 downto 5) <= tbyte;

    -- 10 MHz Clock
    process(CLK,RST)
    begin
        if RST = '1' then
            divtimer <= "0000";
            clkdiv <= '1';
        elsif rising_edge(CLK) then
            if ( divtimer = "0100" ) then
                divtimer <= divtimer + "0001";
                clkdiv <= '1';
            elsif ( divtimer = "1001" ) then
                divtimer <= "0000";
                clkdiv <= '0';
            else
                divtimer <= divtimer + "0001";
            end if;
        end if;
    end process;

    -- 0.3125 MHz clock
    process(CLK,RST)
    begin
        if RST = '1' then
            medtimer <= "00000";
        elsif rising_edge(CLK) then
            if divtimer = "0000" then
                medtimer <= medtimer + "1";
            end if;
        end if;
    end process;
    pol <= medtimer(4);

    -- 1/4 Hz Clock
    process(CLK,RST,divtimer)
    begin
        if RST = '1' then
            slowtimer <= X"00000000";
            spol <= '0';
        elsif rising_edge(CLK) and divtimer = "0000" then
            if slowtimer = X"026259ff" then    -- 98967f
                slowtimer <= X"00000000";
                spol <= '0';
            else
                if slowtimer = X"01312cff" then  -- 4c4b40
                    spol <= '1';
                end if;
                slowtimer <= slowtimer + "01";
            end if;
        end if;
    end process;

    -- Shift out the data, count bits
    process(RST,sclken,CLK,divtimer)
    begin
        if RST = '1' then
            SDIN <= '0';
            sclken <= '0';
            CS <= '1';
--    elsif falling_edge(clkdiv) then
        elsif falling_edge(CLK) and divtimer = "0000" then
            if txdone = '0' and sclken = '0' then
                sclken <= '1';
                SDIN <= txdata(7);
                txbuf <= txdata(6 downto 0) & '0';
                txbit <= "0000";
                CS <= '0';
            elsif sclken = '1' then
                if txbit = "0111" then
                    sclken <= '0';
                    CS <= '1';
                    txbit <= "0000";
                else
                    SDIN <= txbuf(7);
                    txbuf <= txbuf(6 downto 0) & '0';
                    txbit <= txbit + "0001";
                end if;
            end if;
        end if;
    end process;

    process(RST,CLK)
    begin
        if RST = '1' then
            txdone <= '1';
        elsif falling_edge(CLK) then
            if txgo = '1' and txdone = '1' then
                txdone <= '0';
            elsif txgo = '0' and txdone = '0' and sclken = '0' then
                txdone <= '1';
            end if;
        end if;
    end process;

    -- Set data to transmit
    process(RST,CLK)
        variable oldu : std_logic;
        variable oldd : std_logic;
        variable page : std_logic_vector(2 downto 0);

        variable oldpol : std_logic;
        variable mov : std_logic;
    begin
        if RST = '1' then
            state <= "000";
            txgo <= '0';
            DATA <= '0';
            page := "001";

            trow <= "000";
            tcol <= "0000000";
            tbyte <= "001";
            tchar <= "10101";
            oldpol := '0';
            mov := '0';
        elsif rising_edge(CLK) then
            if pwr = '1' and txdone = '1' then
                case state is
                    when "000" =>
                        txdata <= "10001101"; -- 8D, charge pump on
                        txgo <= '1';
                        state <= "001";
                        DATA <= '0';
                    when "001" =>
                        txdata <= "00010100"; -- 14, charge pump on
                        txgo <= '1';
                        state <= "010";
                        DATA <= '0';
                    when "010" =>
                        txdata <= "10101111"; -- AF, display on
                        txgo <= '1';
                        state <= "011";
                        DATA <= '0';
                    when "011" =>
                        txdata <= "10110" & page; -- Set page
                        txgo <= '1';
                        state <= "111";
                        DATA <= '0';
                    when others =>
                        if pol /= oldpol then  -- on a slow tick...
                            if page /= trow then
                                txdata <= "10110" & trow;
                                txgo <= '1';
                                DATA <= '0';
                                page := trow;
                            else
                                if page(0) = '0' then
                                    txdata <= '0' & RAMA(4) & '0' & RAMA(5) & '0' & RAMA(6) & '0' & RAMA(7);
                                else
                                    txdata <= '0' & RAMA(0) & '0' & RAMA(1) & '0' & RAMA(2) & '0' & RAMA(3);
                                end if;
                                txgo <= '1';
                                DATA <= '1';
                                tcol <= tcol + "1";
                                if tcol = "1111111" then
                                    trow <= trow + "1";
                                    tbyte <= "001";
                                    tchar <= "10101";
                                elsif tbyte = "000" then
                                    tbyte <= "101";
                                    tchar <= tchar - "1";
                                else
                                    tbyte <= tbyte - "1";
                                end if;
                                oldpol := pol;
                            end if;
                        end if;
                        state <= "111";
                end case;
            elsif sclken = '1' then
                txgo <= '0';
            end if;
        end if;
    end process;

    SCLK <= clkdiv and sclken;

    -- Vdd and Vbat startup
    process(RST,CLK)
    begin
        if RST = '1' then
--            LED(1 downto 0) <= "00";
            VDD <= '1';
            VBAT <= '1';
            RES <= '0';
        elsif falling_edge(CLK) then
            if itimer = X"000001" then -- 1 ticks
--                LED(1 downto 0) <= "01";
                VDD <= '0';
            elsif itimer = X"00012d" then -- 301 ticks (3.01 uS)
--                LED(1 downto 0) <= "11";
                VBAT <= '0';
                RES <= '1';
            end if;
        end if;
    end process;

    -- Timer for power system startup
    process(RST,CLK)
    begin
        if RST = '1' then
            pwr <= '0';
            ptimer <= '0';
        elsif rising_edge(CLK) then
            if pwr = '1' then
                ptimer <= '0';
                pwr <= '1';
            elsif itimer = X"9897ad" then -- 10 Mticks + 301 (>100 ms)
--      elsif itimer = "000000000000001000101101" then
                ptimer <= '0';
                pwr <= '1';
            else
                ptimer <= '1';
                pwr <= '0';
            end if;
        end if;
    end process;
--    LED(2) <= pwr;

    -- Timer
    process(CLK,RST)
    begin
        if RST = '1' then
            itimer <= X"000000";
        elsif rising_edge(clk) then
            if ptimer = '1' then
                itimer <= itimer + X"000001";
            else
                itimer <= X"000000";
            end if;
        end if;
    end process;


    -- GBCPU

    ADDRCPU(13 downto 3) <= ABUS(10 downto 0);
    ADDRCPU(2 downto 0) <= "000";

    RAM <= DOA_CART(7 downto 0) WHEN ABUS(15 downto 11) = "00000" else  -- 0000-07FF
            "ZZZZZZZZ";

    -- Component Instantiation
    uut: microcode PORT MAP(
        ABUS => ABUS,
        RAM => RAM,
        CLK => spol,
        CLK90 => '0',
        RST => RST
    );

    cartram : RAMB16BWER
    generic map (
        -- DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        -- DOA_REG/DOB_REG: Optional output register (0 or 1)
        DOA_REG => 0,
        DOB_REG => 0,
        -- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- INITP_00 to INITP_07: Initial memory contents.
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        -- INIT_00 to INIT_3F: Initial memory contents.
--      INIT_00 => X"00000000000000002f833eff0721fe36ff06210536ff0721000000cf40e0913e",
--      INIT_00 => X"0000000000000000000003202414043323130332221202fffe314264012c2c00",
        -- 0000 NOP         00
        -- 0001 LD B,ff     06 ff
        -- 0003 LD D,02     16 02
        -- 0005 LD H,04     26 04
        -- 0007 LD (HL),06  36 06
        -- 0009 LD C,01     0e 01
        -- 000b LD E,03     1e 03
        -- 000d LD L,05     2e 05
        -- 000f LD A,07     3e 07
        -- 0011 LD BC,0000  01 00 00
        -- 0014 LD A,(BC)   0a
        -- 0015 LD DE,0001  11 01 00
        -- 0018 LD A,(DE)   1a
        -- 0019 LD SP,fffe  31 fe ff
        -- 001c LD HL,0019  21 19 00
        -- 001f LD A,(HL+)  2A
        INIT_00 => X"2a001921fffe311a0001110a000001073e052e031e010e063604260216ff0600",
        -- 0020 LD A,(HL+)  2A
        -- 0021 LD A,(HL-)  3A
        -- 0022 LD A,bb     3e bb
        -- 0023 LD (BC),A   02
        -- 0024 LD (DE),A   12
        -- 0025 LD (HL+),A  22
        -- 0026 LD (HL-),A  32
        -- 0027 INC BC      03
        -- 0028 INC DE      13
        -- 0029 INC HL      23
        -- 002a INC SP      33
        -- 002b DEC BC      0b
        -- 002c DEC DE      1b
        -- 002d DEC HL      2b
        -- 002e DEC SP      3b
        -- 002f NOP
        -- 0030 LD BC,0800  01 00 08
        -- 0033 LD DE,c800  11 00 c8
        -- 0036 LD SP,c800  31 00 c8
        -- Test addition, and H and C flags, but not Z flag - do later
        -- 0039 ADD HL,BC   09
        -- 003a ADD HL,DE   19
        -- 003b ADD HL,SP   39
        -- 003c ADD HL,HL   29
        -- 003d NOP
        -- 003e NOP
        -- 003f NOP
        INIT_01 => X"00000029391909c80031c800110800013b2b1b0b3323130332221202bb3e3a2a",
        -- 0040 LD B, 0f    06 0f
        -- 0042 INC B       04
        -- 0043 LD C, ff    0e ff
        -- 0045 INC C       0c
        -- 0046 INC D       14
        -- 0047 INC E       1c
        -- 0048 INC H       24
        -- 0049 INC L       2c
        -- 004a INC (HL)    34
        -- 004b INC A       3c
        -- 004c DEC B       05
        -- 004d DEC C       0d
        -- 004e DEC D       15
        -- 004f DEC E       1d
        -- 0050 DEC H       25
        -- 0051 DEC L       2d
        -- 0052 DEC (HL)    35
        -- 0053 DEC A       3d
        INIT_02 => X"0000000000000000000000003d352d251d150d053c342c241c140cff0e040f06",
        -- INIT_A/INIT_B: Initial values on output port
        INIT_A => X"000000000",
        INIT_B => X"000000000",
        -- INIT_FILE: Optional file used to specify initial RAM contents
        INIT_FILE => "NONE",
        -- RSTTYPE: "SYNC" or "ASYNC"
        RSTTYPE => "SYNC",
        -- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        -- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
        SIM_COLLISION_CHECK => "ALL",
        -- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
        SIM_DEVICE => "SPARTAN6", -- was: "SPARTAN3ADSP",
        -- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
        SRVAL_A => X"000000000",
        SRVAL_B => X"000000000",
        -- WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
        WRITE_MODE_A => "WRITE_FIRST",
        WRITE_MODE_B => "WRITE_FIRST"
    )
    port map (
        -- Port A
        DOA => DOA_CART,  -- 32-bit output: A port data output
--      DOPA => DOPA,     -- 4-bit output: A port parity output
        ADDRA => ADDRCPU,   -- 14-bit input: A port address input
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => X"00000000",       -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B
--      DOB => DOB,       -- 32-bit output: B port data output
--      DOPB => DOPB,     -- 4-bit output: B port parity output
        ADDRB => "00" & X"000",   -- 14-bit input: B port address input
        CLKB => '0',      -- 1-bit input: B port clock input
        ENB => '0',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000",       -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

end Behavioral;

