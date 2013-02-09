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


	signal envtimer : unsigned(2 downto 0);
	signal envval : unsigned(3 downto 0);

	signal seqdiv : unsigned(15 downto 0);
	signal seq256, seq128, seq64 : std_logic;
begin

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
			if sysclk_delay = '0' and sysclk = '1' then
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

	-- Envelope generator
	process(rst,clk)
		variable old : std_logic;
	begin
		if rst = '1' then
			envtimer <= (others => '0');
			envval <= (others => '0');
			old := '0';
		elsif rising_edge(clk) then
			if wr_en = '1' and abus = X"FF26" and dbus(7) = '1' then
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

end Behaviour;
