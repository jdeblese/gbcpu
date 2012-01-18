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

-- Possible reduced opcode map:
--     000  001  010  011  100  101  110  111
-- 000 ADD  ADC  SUB  SBC  AND  XOR   OR   CP
-- 001 INC  DEC   -    -    -    -    -    -
-- 010 RLC   RL  RRC   RR  SLA  SRA  SRL  SWP
-- 011  -    -    -    -    -    -    -    -
-- 100 BIT0 BIT1 BIT2 BIT3 BIT4 BIT5 BIT6 BIT7
-- 101 SET0 SET1 SET2 SET3 SET4 SET5 SET6 SET7
-- 110 RES0 RES1 RES2 RES3 RES4 RES5 RES6 RES7
-- 111  -    -    -    -    -    -    -    -

entity alu is
    Port (  IDATA   : in std_logic_vector(7 downto 0);          -- First operand
            ACC     : in std_logic_vector(7 downto 0);          -- Second operand
            ODATA   : out std_logic_vector(7 downto 0);         -- Result
            CE      : in std_logic;                             -- Output latch clock enable
            CMD     : in std_logic_vector(8 downto 0);          -- CMD = X"CB"  &  CMD
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
    signal arith : std_logic_vector(7 downto 0);                -- concatenation of nibbles
    signal logic : std_logic_vector(7 downto 0);                -- ACC and/or/xor IDATA

    signal z_en : std_logic;

begin

    neg <= not IDATA + X"01";

    with addsub select
        muxed <= neg when '1',
                 idata when others;

    with cen select
        carry <= CIN when '1',
                 '0' when others;

    with accmux select
        adata <= ACC when "10",
                 X"FF" when "01",       -- -1
                 X"01" when "00",       -- +1
                 X"00" when others;

    niblo <= ('0' & adata(3 downto 0)) + ('0' & muxed(3 downto 0)) + (X"0" & carry);
    nibhi <= ('0' & adata(7 downto 4)) + ('0' & muxed(7 downto 4)) + (X"0" & niblo(4));
    arith <= nibhi(3 downto 0) & niblo(3 downto 0);

    with CMD(7 downto 3) select
        logic <= ACC and IDATA when "10100",                              -- AND
                 ACC xor IDATA  when "10101",                             -- XOR
                 ACC or IDATA when "10110",                               -- OR
                 X"00" when others;

    comb_proc : process(CMD)
    begin

        addsub <= '0';
        accmux <= "10";
        cen <= '0';

        if CMD(8) = '0' then
            if CMD(7 downto 6) = "00" then
                if CMD(5 downto 0) = "101111" then  -- CPL as "2cpl(ACC) - 1"
                    accmux <= "01";
                    addsub <= '1';
                else                                -- INC, DEC
                    accmux <= CMD(1 downto 0);
                end if;
            elsif CMD(5 downto 4) = "00" then    -- ADD, ADC
                cen <= cmd(3);
            elsif CMD(5 downto 4) = "01" then -- SUB, SBC
                addsub <= '1';
                cen <= cmd(3);
            elsif CMD(5 downto 3) = "111" then -- CP
                addsub <= '1';
            end if;
        end if;
    end process;

    out_proc : process(CLK, CE, RST)
        variable inter : std_logic_vector(7 downto 0);
    begin
        if RST = '1' then
            ODATA <= X"EE";
        elsif rising_edge(CLK) and CE = '1' then
            z_en <= '1';
            ZOUT <= ZIN;
            NOUT <= NIN;
            HOUT <= HIN;
            COUT <= CIN;

            if CMD(8) = '0' then
                inter := arith;

                if addsub = '0' then
                    COUT <= nibhi(4);
                    HOUT <= niblo(4);
                else
                    COUT <= not nibhi(4);
                    HOUT <= not niblo(4);
                end if;
                NOUT <= '0';

                if CMD(7 downto 6) = "00" then
                    if CMD(5 downto 0) = "101111" then  -- CPL
                        COUT <= CIN;
                        NOUT <= '1';
                        HOUT <= '1';
                        z_en <= '0';
                    else                                -- INC, DEC
                        COUT <= CIN;
                        NOUT <= CMD(0);
                    end if;
                elsif CMD(5 downto 4) = "01" then -- SUB, SBC
                    NOUT <= '1';
                elsif CMD(5 downto 3) = "111" then -- CP
                    ODATA <= ACC;
                    NOUT <= '1';
                elsif CMD(5 downto 4) = "10" then -- AND, XOR
                    HOUT <= not CMD(3); -- set for AND, reset for XOR
                    COUT <= '0';
                    inter := logic;
                elsif CMD(5 downto 3) = "110" then -- OR
                    HOUT <= '0';
                    COUT <= '0';
                    inter := logic;
                end if;     -- Nothing special for ADD, ADC

                ODATA <= inter;
                if z_en = '1' then
                    if inter = X"00" then
                        ZOUT <= '1';
                    else
                        ZOUT <= '0';
                    end if;
                end if;

            else    -- CB (bitwise) operation
                ODATA <= IDATA;
                if CMD(7 downto 6) = "00" then -- Bit move operation
                    NOUT <= '0';
                    HOUT <= '0';
                    case CMD(5 downto 3) is
                        when "000" =>   -- RLC
                            inter := IDATA(6 downto 0) & IDATA(7);
                            COUT <= IDATA(7);
                        when "010" =>   -- RL
                            inter := IDATA(6 downto 0) & CIN;
                            COUT <= IDATA(7);
                        when "001" =>   -- RRC
                            inter := IDATA(0) & IDATA(7 downto 1);
                            COUT <= IDATA(0);
                        when "011" =>   -- RR
                            inter := CIN & IDATA(7 downto 1);
                            COUT <= IDATA(0);
                        when "100" =>   -- SLA
                            inter := IDATA(6 downto 0) & '0';
                            COUT <= IDATA(7);
                        when "101" =>   -- SRA
                            inter := IDATA(7) & IDATA(7 downto 1);
                            COUT <= IDATA(0);
                        when "111" =>   -- SRL
                            inter := '0' & IDATA(7 downto 1);
                            COUT <= IDATA(0);
                        when "110" =>   -- SWAP
                            inter := IDATA(3 downto 0) & IDATA(7 downto 4);
                            COUT <= '0';
                        when others =>
                            inter := X"00";
                            COUT <= '0';
                    end case;
                    ODATA <= inter;
                    if z_en = '1' then
                        if inter = X"00" then
                            ZOUT <= '1';
                        else
                            ZOUT <= '0';
                        end if;
                    end if;
                else    -- Single bit operation
                    for I in 0 to 7 loop
                        if I = CMD(5 downto 3) then
                            case CMD(7 downto 6) is
                                when "01" =>    -- BIT b,r
                                    ZOUT <= not IDATA(I);
                                    NOUT <= '0';
                                    HOUT <= '1';
                                when "10" =>    -- SET b,r
                                    ODATA(I) <= '1';
                                when "11" =>    -- RES b,r
                                    ODATA(I) <= '0';
                                when others =>
                                    null;
                            end case;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

end Behaviour;
