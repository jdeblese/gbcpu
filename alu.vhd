library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity alu is
    Port (  IDATA   : in std_logic_vector(7 downto 0);
            ACC     : in std_logic_vector(7 downto 0);
            ODATA   : out std_logic_vector(7 downto 0);
            CE      : in std_logic;
            CMD     : in std_logic_vector(8 downto 0);
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

    signal neg : std_logic_vector(7 downto 0);
    signal addsub : std_logic;
    signal muxed : std_logic_vector(7 downto 0);
    signal accmux : std_logic_vector(1 downto 0);
    signal adata : std_logic_vector(7 downto 0);

    signal carry : std_logic;
    signal cen : std_logic;

    signal niblo, nibhi : std_logic_vector(4 downto 0);
    signal arith : std_logic_vector(7 downto 0);
    signal logic : std_logic_vector(7 downto 0);

    signal oper : std_logic_vector(3 downto 0);
    signal half : std_logic_vector(4 downto 0);

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
            if CMD(7 downto 4) = "1000" then    -- ADD, ADC
                cen <= cmd(3);
            elsif CMD(7 downto 4) = "1001" then -- SUB, SBC
                addsub <= '1';
                cen <= cmd(3);
            elsif CMD(7 downto 3) = "10111" then -- CP
                addsub <= '1';
            elsif CMD(7 downto 6) = "00" then -- INC, DEC
                accmux <= CMD(1 downto 0);
            end if;
        end if;
    end process;

    out_proc : process(CLK, CE, RST)
    begin
        if RST = '1' then
            ODATA <= X"EE";
        elsif falling_edge(CLK) and CE = '1' then
            ZOUT <= ZIN;
            NOUT <= NIN;
            HOUT <= HIN;
            COUT <= CIN;

            if CMD(8) = '0' then
                ODATA <= arith;

                COUT <= nibhi(4);
                HOUT <= niblo(4);
                NOUT <= '0';

                if arith = X"00" then
                    ZOUT <= '1';
                else
                    ZOUT <= '0';
                end if;

                if CMD(7 downto 4) = "1001" then -- SUB, SBC
                    NOUT <= '1';
                elsif CMD(7 downto 3) = "10111" then -- CP
                    ODATA <= X"00";
                    NOUT <= '1';
                elsif CMD(7 downto 4) = "1010" then -- AND, XOR
                    HOUT <= not CMD(3); -- set for AND, reset for XOR
                    COUT <= '0';
                    ODATA <= logic;
                elsif CMD(7 downto 3) = "10110" then -- OR
                    HOUT <= '0';
                    COUT <= '0';
                    ODATA <= logic;
                elsif CMD(7 downto 6) = "00" then -- INC, DEC
                    COUT <= CIN;
                    NOUT <= CMD(0);
                end if;

            else    -- CB (bitwise) operation
                ODATA <= IDATA;
                if CMD(7 downto 6) = "00" then -- Bit move operation
                    null;
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
