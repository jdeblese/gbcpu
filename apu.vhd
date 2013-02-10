library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apu is
	port (
		abus : in std_logic_vector(15 downto 0);
		dbus : in std_logic_vector(7 downto 0);
		wr_en : in std_logic;
		pcm : out std_logic_vector(3 downto 0);
		sysclk : in std_logic; -- 4194304 Hz
		clk : in std_logic;
		rst : in std_logic );
end apu;

architecture Behaviour of apu is

	signal sysclk_delay : std_logic;

	signal NR12 : std_logic_vector(7 downto 0);
	signal power : std_logic;

	signal init : std_logic;

	signal envtimer : unsigned(2 downto 0);
	signal envval : unsigned(3 downto 0);

	signal lencnt_en : std_logic;
	signal lencnt : unsigned(5 downto 0);

	signal seqdiv : unsigned(15 downto 0);
	signal seq256, seq128, seq64 : std_logic;

	signal progfreq : std_logic_vector(10 downto 0);
	signal progcnt : unsigned(10 downto 0);
	signal progtc : std_logic;

	signal duty : std_logic_vector(1 downto 0);
	signal dutycnt : unsigned(2 downto 0);
	signal dutywav : std_logic;

	signal channel_en : std_logic;
begin

	-- Master power switch
	process(rst,clk)
	begin
		if rst = '1' then
			power <= '0';
		elsif rising_edge(clk) then
			if wr_en = '1' and abus = X"FF26" then
				power <= dbus(7);
			end if;
		end if;
	end process;

	-- Channel enable
	-- enabled on trigger, a write of '1' to bit 7 of NRx4
	-- enable sits between duty cycle generator and envelope generator
	-- disabled by length counter reaching 0
	process(rst,clk)
	begin
		if rst = '1' then
			channel_en <= '0';
		elsif rising_edge(clk) then
			if wr_en = '1' and abus = X"FF14" then
				channel_en <= dbus(7);
			end if;
		end if;
	end process;

	-- Register write access
	process(rst,clk)
	begin
		if rst = '1' then
			NR12 <= (others => '0');
		elsif rising_edge(clk) then
			if wr_en = '1' then
				if abus = X"FF12" then
					NR12 <= dbus;
				elsif abus = X"FF26" then
					power <= dbus(7);
				end if;
			end if;
		end if;
	end process;

	-- Init, strobed for 1 clock cycle on a write to FF14(7)
	process(rst,clk)
		variable old : std_logic;
	begin
		if rst = '1' then
			init <= '0';
			old := '0';
		elsif rising_edge(clk) then
			init <= '1';
			if old = '0' and wr_en = '1' and abus = X"FF14" and dbus(7) = '1' then
				init <= '1';
				old := '1';
			elsif wr_en = '0' then
				old := '0';
			end if;
		end if;
	end process;


	-- edge detect
	process(rst,clk)
	begin
		if rst = '1' then
			sysclk_delay <= '0';
		elsif rising_edge(clk) then
			if sysclk_delay = '0' and sysclk = '1' then
				sysclk_delay <= '1';
			elsif sysclk_delay = '1' and sysclk = '0' then
				sysclk_delay <= '0';
			end if;
		end if;
	end process;

	-- Frame sequencer divider
	process(rst,clk)
	begin
		if rst = '1' then
			seqdiv <= (others => '0');
		elsif rising_edge(clk) then
			if power = '0' then  -- sequencer is disabled but not 512 Hz timer, according to GbdevWiki
				seqdiv <= (others => '0');
			elsif sysclk_delay = '0' and sysclk = '1' then
				seqdiv <= seqdiv + "1";
			end if;
		end if;
	end process;

	-- Frame sequencer clocks (timing according to GbdevWiki
	seq256 <= seqdiv(13);
	with seqdiv(15 downto 13) select
		seq128 <= '1' when "010",
		          '1' when "110",
		          '0' when others;
	with seqdiv(15 downto 13) select
		seq64 <= '1' when "111",
		         '0' when others;


	-- Ch1 Programmable Counter
	process(rst,clk)
		variable old_wr, old_clk : std_logic;
	begin
		if rst = '1' then
			progcnt <= (others => '0');
			progfreq <= (others => '1');
			progtc <= '0';
			old_wr := '0';
			old_clk := '0';
		elsif rising_edge(clk) then
			progtc <= '0';

			-- writes to the length counter registers
			if power = '0' then
				progfreq <= (others => '1');
			elsif old_wr = '0' and wr_en = '1' then
				-- save the frequency and reload the counter
				if abus = X"FF13" then
					progfreq(7 downto 0) <= dbus(7 downto 0);
					progcnt <= unsigned(not(progfreq(10 downto 8) & dbus(7 downto 0)));
				elsif abus = X"FF14" then
					progfreq(10 downto 8) <= dbus(2 downto 0);
					progcnt <= unsigned(not(dbus(2 downto 0) & progfreq(7 downto 0)));
				end if;
			end if;

			-- the actual counting, clocked by sysclk/4
			if power = '0' then
				progcnt <= (others => '0');
			elsif old_clk = '0' and seqdiv(1) = '1' then
				if progcnt = "0" then
					progtc <= '1';
					progcnt <= unsigned(not(progfreq));
				else
					progcnt <= progcnt - 1;
				end if;
			end if;

			old_wr := wr_en;
			old_clk := seqdiv(1);
		end if;
	end process;

	-- Ch1 Duty Cycle Generator
	process(rst,clk)
		variable old_wr, old_clk, wav : std_logic;
	begin
		if rst = '1' then
			dutycnt <= (others => '0');
			duty <= "10";  -- Channel 1 initial value is 50%
			old_wr := '0';
			old_clk := '0';
			wav := '0';
			dutywav <= '0';
		elsif rising_edge(clk) then

			-- writes to the duty cycle register
			if power = '0' then
				duty <= "10";  -- Channel 1 initial value is 50%
			elsif old_wr = '0' and wr_en = '1' then
				if abus = X"FF11" then
					duty <= dbus(7 downto 6);
				end if;
			end if;

			-- the actual counting, clocked by sysclk/4
			if power = '0' then
				dutycnt <= (others => '0');
			elsif old_clk = '0' and progtc = '1' then
				dutycnt <= dutycnt + 1;
			end if;

			-- Waveform generation
			wav := '0';
			if dutycnt = 4 or (dutycnt = 5 and duty /= "00") or (dutycnt(2 downto 1) = "01" and duty = "10") then
				wav := '1';
			end if;
			if duty = "11" then  -- 75% duty cycle is not(25%)
				dutywav <= not(wav);
			else
				dutywav <= wav;
			end if;

			old_wr := wr_en;
			old_clk := progtc;
		end if;
	end process;


	-- Envelope generator
	process(rst,clk)
		variable old : std_logic;
	begin
		if rst = '1' then
			envtimer <= (others => '0');
			envval <= (others => '0');
			old := '0';
		elsif rising_edge(clk) then
			if init = '1' then
				-- Set the envelope timer and value on INIT
				if seqdiv(15 downto 13) = "110" then
					-- Odd behavior taken from GbdevWiki
					envtimer <= unsigned(NR12(2 downto 0)) + "1";
				else
					envtimer <= unsigned(NR12(2 downto 0));
				end if;
				envval <= unsigned(NR12(7 downto 4));
			elsif power = '1' and old = '0' and seq64 = '1' then
				-- Count down at 64 Hz, reloading + stepping the volume on underflow
				if envtimer = "0" then
					envtimer <= unsigned(NR12(2 downto 0));
					if NR12(3) = '0' and envval /= "0000" then
						envval <= envval - "1";
					elsif NR12(3) = '1' and envval /= "1111" then
						envval <= envval + "1";
					end if;
				else
					envtimer <= envtimer - "1";
				end if;
			end if;
			old := seq64;
		end if;
	end process;
	pcm <= std_logic_vector(envval);

	-- Length counter
	-- Decrements when enabled by NRx4, disables channel when decrements to zero
	process(rst,clk)
	begin
		if rst = '1' then
			lencnt_en <= '0';
		elsif rising_edge(clk) then
			if wr_en = '1' and abus = X"FF14" then
				lencnt_en <= dbus(6);
			end if;
		end if;
	end process;


	-- On length counter enable (rising edge NR14(6))
	--   on seq256 = '1'
	--     decrement length counter
	--     if length counter is now zero and "trigger is clear"(???), disable channel

	-- On channel trigger (rising edge NR14(7))
	--   on seq256 = '1'
	--     if length counter is enabled and value = "0"
	--       value = "63"
	--   on seq256 = '0'
	--     if length counter is enabled and value = "0"
	--       value = 63 or 64?

	process(rst,clk)
		variable old_wr, old256 : std_logic;
	begin
		if rst = '1' then
			lencnt <= (others => '0');
			old_wr := '0';
			old256 := '0';
		elsif rising_edge(clk) then
			-- writes to the length counter registers
			if old_wr = '0' and wr_en = '1' then
				if abus = X"FF11" then
					lencnt <= unsigned(not(dbus(5 downto 0))) - "1";
				elsif abus = X"FF14" and lencnt = "0" then
					-- Should actually be set to 64, not 63...
					lencnt <= "111111";
				end if;
			end if;
			-- the actual counting
			if old256 = '0' and seq256 = '1' and lencnt_en = '1' and lencnt /= "0" then
				lencnt <= lencnt - "1";
			end if;
			old_wr := wr_en;
			old256 := seq256;
		end if;
	end process;

end Behaviour;
