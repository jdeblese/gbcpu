----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:27:51 11/22/2011 
-- Design Name: 
-- Module Name:    debouncer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all ;

entity debouncer is
	Port ( 
		rst : in std_logic;
		btn : in  STD_LOGIC;
		clk : in  STD_LOGIC;
		filtered : out  STD_LOGIC);
			  
end debouncer;

architecture Behavioral of debouncer is
	signal count : std_logic_vector(14 downto 0);
	signal sreg : std_logic_vector(15 downto 0);
	signal state : std_logic;
begin

	filtered <= state;

	clkdiv : process(rst,clk)
	begin
		if rst = '1' then
			count <= "000000000000000";
		elsif rising_edge(clk) then
			count <= count + "01";
		end if;
	end process;
	
	-- http://www.ganssle.com/debouncing-pt2.htm
	shifter : process(rst,clk,count)
	begin
		if rst = '1' then
			sreg <= "0000000000000000";
		elsif rising_edge(clk) and count = "0" then
			sreg <= sreg(14 downto 0) & btn;
		end if;
	end process;
		
	output : process(rst,clk)
	begin
		if rst = '1' then
			state <= '0';
		elsif rising_edge(clk) then
			if state = '0' and sreg = "1111111111111111" then
				state <= '1';
			elsif state = '1' and sreg = "0000000000000000" then
				state <= '0';
			end if;
		end if;
	end process;

end Behavioral;

