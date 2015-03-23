library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.Functions.all;

entity FIFO_Controler is
	generic
	(
		addr_size : natural := 4
	);
	port
	(
		tail, head : out std_ulogic_vector(addr_size - 1 downto 0);
		full, empty, free2, have2: out std_ulogic;
		wr1, wr2 : out std_ulogic;
		put1, put2, take1, take2 : in std_ulogic;
		reset : in std_ulogic;
		clk : in std_ulogic
	);
end entity;

architecture FIFO_Controler_arch of FIFO_Controler is
	signal head_addr, tail_addr : std_ulogic_vector(addr_size downto 0);
	signal tailInc, headInc : std_ulogic_vector(addr_size - 1 downto 0);
	signal full_flag, empty_flag : std_ulogic;
	signal free2_flag, have2_flag : std_ulogic;
begin
	tailInc <= tail_addr(addr_size - 1 downto 0) + 1;
	headInc <= head_addr(addr_size - 1 downto 0) + 1;
	process(reset, clk)
		variable inc : integer;
	begin
		if (reset = '1')
		then
			head_addr <= (others => '0');
			tail_addr <= (others => '0');
		elsif rising_edge(clk)
		then
			inc := 0;
			if (put2 = '1' and free2_flag = '1')
			then
				inc := 2;
			elsif (put1 = '1' and full_flag = '0')
			then
				inc := 1;
			end if;
			tail_addr <= tail_addr + inc;

			inc := 0;
			if (take2 = '1' and have2_flag = '1')
			then
				inc := 2;
			elsif (take1 = '1' and empty_flag = '0')
			then
				inc := 1;
			end if;
			head_addr <= head_addr + inc;
		end if;
	end process;
	
	full_flag 	<=	'1' when head_addr(addr_size) /= tail_addr(addr_size) and head_addr(addr_size - 1 downto 0) = tail_addr(addr_size - 1 downto 0) else
					'0';
	empty_flag 	<=	'1' when head_addr(addr_size) = tail_addr(addr_size) and head_addr(addr_size - 1 downto 0) = tail_addr(addr_size - 1 downto 0) else
					'0';
	free2_flag 	<= 	'1' when (full_flag = '0') and (tailInc /= head_addr(addr_size - 1 downto 0)) else
					'0';
	have2_flag <=	'1' when (empty_flag = '0') and (headInc /= tail_addr(addr_size - 1 downto 0)) else
					'0';

	tail 	<= tail_addr(addr_size - 1 downto 0);
	head 	<= head_addr(addr_size - 1 downto 0);
	full 	<= full_flag;
	free2 	<= free2_flag;
	empty 	<= empty_flag;
	have2 	<= have2_flag;
	wr1 	<= 	'1' when reset = '0' and ((put1 = '1' and full_flag = '0') or (put2 = '1' and free2_flag = '1')) else 
				'0';
	wr2 	<= 	'1' when reset = '0' and put2 = '1' and free2_flag = '1' else 
				'0';
end architecture;