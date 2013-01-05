library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity cpuregs is
    Port (  CMD_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            TMP_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            UNQ_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            ACC_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CMD_CE : IN STD_LOGIC;
            TMP_CE : IN STD_LOGIC;
            UNQ_CE : IN STD_LOGIC;
            ACC_CE : IN STD_LOGIC;
            FLAGS_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            FLAGS_IN  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            FLAGS_CE  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            TCK : IN STD_LOGIC;
            TDL : IN STD_LOGIC;
            TDI : IN STD_LOGIC;
            TDO : OUT STD_LOGIC;
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC );
end cpuregs;

architecture Behavioral of cpuregs is

    signal cmd, lcmd : STD_LOGIC_VECTOR(7 downto 0);
    signal acc, lacc : STD_LOGIC_VECTOR(7 downto 0);
    signal tmp : std_logic_vector(7 downto 0);
    signal unq : std_logic_vector(7 downto 0);

    signal flags, lflags : STD_LOGIC_VECTOR(3 downto 0);

begin

    CMD_OUT <= cmd;
    TMP_OUT <= tmp;
    UNQ_OUT <= unq;
    ACC_OUT <= acc;
    FLAGS_OUT <= flags;

    -- *****************************************************************
    -- JTAG Shift Register

    -- Latches data on the rising edge of
    -- TCK when TDL is high. Values shifted
    -- out are (MSB first):
    --   CMD
    --   acc
    --   flags

    -- NOTE: Does TCK need to be resynchronized to this clock domain? Or
    -- the other values to the TCK domain?

    -- Data latching and shifting
    process(TCK, RST)
    begin
        if RST = '1' then
            TDO <= '0';
            lcmd <= X"00";
            lacc <= X"00";
            lflags <= X"0";
        elsif rising_edge(TCK) then
            if TDL = '1' then
                TDO <= cmd(7);
                lcmd <= cmd(6 downto 0) & acc(7);
                lacc <= acc(6 downto 0) & flags(3);
                lflags <= flags(2 downto 0) & TDI;
            else
                TDO <= lcmd(7);
                lcmd <= lcmd(6 downto 0) & lacc(7);
                lacc <= lacc(6 downto 0) & lflags(3);
                lflags <= lflags(2 downto 0) & TDI;
            end if;
        end if;
    end process;

    -- *****************************************************************
    -- Internal Registers --

    -- Accumulator, used as second input to ALU
    acc_proc : process(CLK, RST)
    begin
        if RST = '1' then
            acc <= X"AC";
        elsif rising_edge(CLK) then
            if ACC_CE = '1' then
                acc <= DATA;
            end if;
        end if;
    end process;

    -- Temporary registers
    tmp_proc : process(CLK, RST)
    begin
        if RST = '1' then
            tmp <= "00000000";
        elsif rising_edge(CLK) then
            if TMP_CE = '1' then
                tmp <= DATA;
            end if;
        end if;
    end process;

    unq_proc : process(CLK, RST)
    begin
        if RST = '1' then
            unq <= "00000000";
        elsif rising_edge(CLK) then
            if UNQ_CE = '1' then
                unq <= DATA;
            end if;
        end if;
    end process;

    -- Current command used by ALU
    cmd_proc : process(CLK, RST)
    begin
        if RST = '1' then
            cmd <= "00000000";
        elsif rising_edge(CLK) then
            if CMD_CE = '1' then
                cmd <= DATA;
            end if;
        end if;
    end process;

    -- ALU flag registers
    process(CLK, RST)
    begin
        if (RST = '1') then
            flags <= (others => '0');
        elsif rising_edge(CLK) then
            if FLAGS_CE(0) = '1' then
                flags(0) <= FLAGS_IN(0);
            end if;
            if FLAGS_CE(1) = '1' then
                flags(1) <= FLAGS_IN(1);
            end if;
            if FLAGS_CE(2) = '1' then
                flags(2) <= FLAGS_IN(2);
            end if;
            if FLAGS_CE(3) = '1' then
                flags(3) <= FLAGS_IN(3);
            end if;
        end if;
    end process;

end Behavioral;
