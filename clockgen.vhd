library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package clockgen_comp is
    type clockgen_status is record
        done      : std_logic;
        locked    : std_logic;
        clkin_err : std_logic;
        clkfx_err : std_logic;
    end record;

    component clockgen
    port (
        master   : in std_logic;
        fastclk  : out std_logic;
        fastclkn : out std_logic;
        cpuclk   : out std_logic;
        pixclk   : out std_logic;
        status   : out clockgen_status;
        rst      : in std_logic );
    end component;

end package;

use work.clockgen_comp.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity clockgen is
    port (
        master   : in std_logic;
        fastclk  : out std_logic;
        fastclkn : out std_logic;
        cpuclk   : out std_logic;
        pixclk   : out std_logic;
        status   : out clockgen_status;
        rst      : in std_logic );
end clockgen;

architecture Behaviour of clockgen is
    signal master_buf : std_logic;
    signal clk2x_ub, clk2xn_ub : std_logic;
    signal cpuclk_ub, pixclk_ub : std_logic;
    signal clkfb : std_logic;
    signal statvec : std_logic_vector(7 downto 0);
begin

    -- Is this buffer really required?
    ibuf : BUFIO2
    generic map (
       DIVIDE => 1,           -- DIVCLK divider (1-8)
       DIVIDE_BYPASS => TRUE, -- Bypass the divider circuitry (TRUE -> DIVCLK is passthrough)
       I_INVERT => FALSE,     -- Invert clock (TRUE/FALSE)
       USE_DOUBLER => FALSE   -- Use doubler circuitry (TRUE/FALSE)
    )
    port map (
       I => master,          -- 1-bit input: Clock input (connect to IBUFG)
       DIVCLK => master_buf, -- 1-bit output: Divided clock output
       IOCLK => open,        -- 1-bit output: I/O output clock
       SERDESSTROBE => open  -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
    );

    -- Minimum output frequency of FX is 5 MHz, so have to use CLKDV instead
    dcm : DCM_SP
    generic map (
        CLKIN_PERIOD => 10.0,                  -- 10 ns clock period, assuming 100 MHz clock
        CLKIN_DIVIDE_BY_2 => TRUE,             -- CLKIN divide by two (TRUE/FALSE)
        CLK_FEEDBACK => "2X",                  -- Feedback source (NONE, 1X, 2X)
        CLKDV_DIVIDE => 12.0,                  -- CLKDV divide value
        CLKFX_DIVIDE => 5,                     -- Divide value on CLKFX outputs
        CLKFX_MULTIPLY => 4,                   -- Multiply value on CLKFX outputs
        CLKOUT_PHASE_SHIFT => "NONE",          -- Output phase shift (NONE, FIXED, VARIABLE)
        DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
        STARTUP_WAIT => FALSE                  -- Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
    )
    port map (
        RST => rst,             -- 1-bit input: Active high reset input
        CLKIN => master,        -- 1-bit input: Clock input
        CLKFB => clkfb,         -- 1-bit input: Clock feedback input
        CLK2X => clk2x_ub,      -- 1-bit output: 2X clock frequency clock output
        CLK2X180 => clk2xn_ub,  -- 1-bit output: 2X clock frequency, 180 degree clock output
        CLKFX => pixclk_ub,     -- 1-bit output: Digital Frequency Synthesizer output (DFS)
        CLKFX180 => open,       -- 1-bit output: 180 degree CLKFX output
        CLKDV => cpuclk_ub,     -- 1-bit output: Divided clock output
        CLK0 => open,           -- 1-bit output: 0 degree clock output
        CLK90 => open,          -- 1-bit output: 90 degree clock output
        CLK180 => open,         -- 1-bit output: 180 degree clock output
        CLK270 => open,         -- 1-bit output: 270 degree clock output
        LOCKED => status.locked,-- 1-bit output: DCM_SP Lock Output
        PSDONE => status.done,  -- 1-bit output: Phase shift done output
        STATUS => statvec,      -- 8-bit output: DCM_SP status output
        DSSEN => '0',           -- 1-bit input: Unsupported, specify to GND.
        PSCLK => open,          -- 1-bit input: Phase shift clock input
        PSEN => open,           -- 1-bit input: Phase shift enable
        PSINCDEC => open        -- 1-bit input: Phase shift increment/decrement input
    );

    -- Required for BUFIO2 above
    obuf : BUFIO2FB generic map ( DIVIDE_BYPASS => TRUE ) port map ( I => clk2x_ub, O => clkfb );

    fbuf  : BUFG port map ( I => clk2x_ub,   O => fastclk  );
    fnbuf : BUFG port map ( I => clk2xn_ub,  O => fastclkn );
    cbuf  : BUFG port map ( I => cpuclk_ub,  O => cpuclk   );
    pbuf  : BUFG port map ( I => pixclk_ub,  O => pixclk   );

    status.clkin_err <= statvec(1);
    status.clkfx_err <= statvec(2);

end Behaviour;
