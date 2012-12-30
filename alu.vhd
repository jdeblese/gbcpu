library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- Supported operations:
--  ADD, ADC, SUB, SBC, CP
--  AND, OR, XOR
--  INC, DEC
--  RLC, RL, RRC, RR
--  SLA, SRA, SRL, SWAP
--  BIT, SET, RES
--  DAA, CPL, SCF, CCF

-- Reduced opcode map:
--      000  001  010  011  100  101  110  111
-- 000  ADD  ADC  SUB  SBC             CP      arith
-- 001  INC                 DEC                arith
-- 010  AND   OR  XOR  CPL                     logic
-- 011  DAA       SCF  CCF                     daa
-- 100  RLC   RL  RRC   RR  SLA  SRA  SRL  SWP shift
-- 101 BIT0 BIT1 BIT2 BIT3 BIT4 BIT5 BIT6 BIT7
-- 110 RES0 RES1 RES2 RES3 RES4 RES5 RES6 RES7 bitmod
-- 111 SET0 SET1 SET2 SET3 SET4 SET5 SET6 SET7 bitmod

-- Zero flag map:
--      000  001  010  011  100  101  110  111
-- 000   z    z    z    z              z
-- 001   z                   z
-- 010   z    z    z    -
-- 011   z         -    -
-- 100   z    z    z    z    z    z    z    z
-- 101  ~b   ~b   ~b   ~b   ~b   ~b   ~b   ~b
-- 110   -    -    -    -    -    -    -    -
-- 111   -    -    -    -    -    -    -    -

-- Negative flag map:
--      000  001  010  011  100  101  110  111
-- 000   0    0    1    1              1
-- 001   0                   1
-- 010   0    0    0    1
-- 011   -         0    0
-- 100   0    0    0    0    0    0    0    0
-- 101   0    0    0    0    0    0    0    0
-- 110   -    -    -    -    -    -    -    -
-- 111   -    -    -    -    -    -    -    -

-- Half flag map:
--      000  001  010  011  100  101  110  111
-- 000   h    h    h    h              h
-- 001   h                   h
-- 010   1    0    0    1
-- 011   0         0    0
-- 100   0    0    0    0    0    0    0    0
-- 101   1    1    1    1    1    1    1    1
-- 110   -    -    -    -    -    -    -    -
-- 111   -    -    -    -    -    -    -    -

-- Carry flag map:
--      000  001  010  011  100  101  110  111
-- 000   c    c    c    c              c
-- 001   -                   -
-- 010   0    0    0    -
-- 011   c         1    ~
-- 100   b    b    b    b    b    b    b    0
-- 101   -    -    -    -    -    -    -    -
-- 110   -    -    -    -    -    -    -    -
-- 111   -    -    -    -    -    -    -    -

entity alu is
    Port (  IDATA   : in std_logic_vector(7 downto 0);          -- First operand
            ACC     : in std_logic_vector(7 downto 0);          -- Second operand
            ODATA   : out std_logic_vector(7 downto 0);         -- Result
            CE      : in std_logic;                             -- Output latch clock enable
            CMD     : in std_logic_vector(5 downto 0);
            ZIN     : in std_logic;
            CIN     : in std_logic;
            HIN     : in std_logic;
            NIN     : in std_logic;
            ZOUT    : out std_logic;
            COUT    : out std_logic;
            HOUT    : out std_logic;
            NOUT    : out std_logic;
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC );
end alu;

architecture Behaviour of alu is

    -- Control signals
    signal addsub : std_logic;                      -- Addition (0) or subtraction (1) operation
    signal cen : std_logic;                         -- Enable or disable carry usage
    signal accmux : std_logic_vector(1 downto 0);   -- Select second ALU operand (ACC, -1, +1, 0)

    -- Intermediate values
    signal neg : std_logic_vector(7 downto 0);                  -- 2s complement IDATA
    signal muxed : std_logic_vector(7 downto 0);                -- +IDATA or -IDATA
    signal carry : std_logic;                                   -- CIN or '0'
    signal adata : std_logic_vector(7 downto 0);                -- ACC, -1, +1 or 0
    signal niblo, nibhi : std_logic_vector(4 downto 0);         -- Nibbles of adata + muxed

    -- ALU subblock data outputs
    signal arith : std_logic_vector(7 downto 0);                -- concatenation of nibbles
    signal logic : std_logic_vector(7 downto 0);                -- ACC and/or/xor IDATA
    signal daa : std_logic_vector(7 downto 0);
    signal shifted : std_logic_vector(7 downto 0);
    signal bitmod : std_logic_vector(7 downto 0);

    -- Output data latch
    signal olatch : std_logic_vector(7 downto 0);

    signal z_en : std_logic;

    -- Output flags
    signal targetbit : std_logic;
    signal zflag : std_logic;
    signal acc_c, acc_h : std_logic;
    signal daa_c, daa_h : std_logic;
    signal cbit : std_logic;

begin

    -- IO Data Routing
    process(RST, CLK, CE)
    begin
        if RST = '1' then
            ODATA <= X"00";
        elsif rising_edge(CLK) and CE = '1' then
            ODATA <= olatch;
        end if;
    end process;

    with CMD(5 downto 3) select
        olatch <= arith when "000",
                  arith when "001",
                  logic when "010",      -- AND OR XOR CPL
                  daa when "011",
                  shifted when "100",    -- Shifts
                  bitmod when "110",     -- RES
                  bitmod when "111",     -- SET
                  X"00" when others;

    with olatch select
        zflag <= '1' when X"00",
                 '0' when others;

    -- Arithmetic
    neg <= not IDATA + X"01";

    with CMD(1) select
        muxed <= neg when '1',
                 idata when others;

    with CMD(0) select
        carry <= CIN when '1',
                 '0' when others;

    adata <= ACC when CMD(3) = '0' else     -- + ACC
             X"01" when CMD(2) = '0' else   -- + 1
             X"FF";                         -- - 1

    niblo <= ('0' & adata(3 downto 0)) + ('0' & muxed(3 downto 0)) + (X"0" & carry);
    nibhi <= ('0' & adata(7 downto 4)) + ('0' & muxed(7 downto 4)) + (X"0" & niblo(4));
    arith <= nibhi(3 downto 0) & niblo(3 downto 0);

    with CMD(1) select
        acc_c <= nibhi(4) when '0',
                 not nibhi(4) when others;

    with CMD(1) select
        acc_h <= niblo(4) when '0',
                 not niblo(4) when others;

    -- DAA
    -- TODO: Check documentation to see if h flag is set or not
    lonibble : process(ACC, CIN, HIN, NIN)
        variable inter : std_logic_vector(8 downto 0);
    begin
        if ACC(3 downto 0) > X"9" or HIN = '1' then
            if NIN = '0' then
                inter := ACC + "000000110";
            else
                inter := ACC - "000000110";
            end if;
            daa_h <= '1';
        else
            inter := '0' & ACC;
            daa_h <= '0';
        end if;
        if inter(7 downto 4) > X"9" or CIN = '1' or inter(8) = '1' then
            if NIN = '0' then
                daa <= inter(7 downto 0) + X"60";
            else
                daa <= inter(7 downto 0) - X"60";
            end if;
            daa_c <= '1';
        else
            daa <= inter(7 downto 0);
            daa_c <= '0';
        end if;
    end process;

    -- Logic
    with CMD(1 downto 0) select
        logic <= ACC and IDATA when "00",    -- AND
                 ACC or IDATA when "01",     -- OR
                 ACC xor IDATA  when "10",   -- XOR
                 not ACC when others;        -- NOT

    -- Bit ops
    with CMD(2 downto 0) select
        targetbit <= IDATA(0) when "000",
                     IDATA(1) when "001",
                     IDATA(2) when "010",
                     IDATA(3) when "011",
                     IDATA(4) when "100",
                     IDATA(5) when "101",
                     IDATA(6) when "110",
                     IDATA(7) when others;

    with CMD(2 downto 0) select
        shifted <= IDATA(6 downto 0) & IDATA(7) when "000",     -- RLC
                   IDATA(6 downto 0) & CIN      when "001",     -- RL
                   IDATA(0) & IDATA(7 downto 1) when "010",     -- RRC
                   CIN & IDATA(7 downto 1)      when "011",     -- RR
                   IDATA(6 downto 0) & '0'      when "100",     -- SLA
                   IDATA(7) & IDATA(7 downto 1) when "101",     -- SRA
                   '0' & IDATA(7 downto 1)      when "110",     -- SRL
                   IDATA(3 downto 0) & IDATA(7 downto 4) when others;   -- SWAP

    with CMD(2 downto 0) select
        cbit <= IDATA(7) when "000",    -- RLC
                IDATA(7) when "001",    -- RL
                IDATA(0) when "010",    -- RRC
                IDATA(0) when "011",    -- RR
                IDATA(7) when "100",    -- SLA
                IDATA(0) when "101",    -- SRA
                IDATA(0) when "110",    -- SRL
                '0' when others;        -- SWAP

    with CMD(2 downto 0) select
        bitmod <= IDATA(7 downto 1) & CMD(3) when "000",
                  IDATA(7 downto 2) & CMD(3) & IDATA(0) when "001",
                  IDATA(7 downto 3) & CMD(3) & IDATA(1 downto 0) when "010",
                  IDATA(7 downto 4) & CMD(3) & IDATA(2 downto 0) when "011",
                  IDATA(7 downto 5) & CMD(3) & IDATA(3 downto 0) when "100",
                  IDATA(7 downto 6) & CMD(3) & IDATA(4 downto 0) when "101",
                  IDATA(7) & CMD(3) & IDATA(5 downto 0) when "110",
                  CMD(3) & IDATA(6 downto 0) when others;

    -- Flags
    process(RST, CLK, CE)
    begin
        if RST = '1' then
            ZOUT <= '0';
        elsif rising_edge(CLK) and CE = '1' then
            if CMD(5 downto 3) = "101" then
                ZOUT <= not targetbit;
            else
                ZOUT <= zflag;
            end if;
        end if;
    end process;

    process(RST, CLK, CE)
    begin
        if RST = '1' then
            NOUT <= '0';
        elsif rising_edge(CLK) and CE = '1' then
            if CMD(5 downto 4) = "00" and CMD(2 downto 1) /= "00" then
                NOUT <= '1';
            elsif CMD = "010011" then
                NOUT <= '1';
            else
                NOUT <= '0';
            end if;
        end if;
    end process;

    process(RST, CLK, CE)
    begin
        if RST = '1' then
            HOUT <= '0';
        elsif rising_edge(CLK) and CE = '1' then
            if CMD(5 downto 4) = "00" then
                HOUT <= acc_h;
            elsif CMD(5 downto 3) = "101" then
                HOUT <= '1';
            elsif CMD = "010000" or CMD = "010011" then
                HOUT <= '1';
            else
                HOUT <= '0';
            end if;
        end if;
    end process;

    process(RST, CLK, CE)
    begin
        if RST = '1' then
            COUT <= '0';
        elsif rising_edge(CLK) and CE = '1' then
            if CMD(5 downto 3) = "000" then
                COUT <= acc_c;
            elsif CMD = "011000" then
                COUT <= daa_c;
            elsif CMD(5 downto 3) = "100" then
                COUT <= cbit;
            elsif CMD = "011010" then
                COUT <= '1';
            elsif CMD = "011011" then
                COUT <= not CIN;
            else
                COUT <= '0';
            end if;
        end if;
    end process;

end Behaviour;
