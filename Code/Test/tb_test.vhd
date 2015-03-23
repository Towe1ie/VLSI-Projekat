library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Components.all;
use work.Declarations.all;

entity cpu_test_vhd_tst is end entity;

architecture cpu_test_vhd_tst_arch of cpu_test_vhd_tst is
	signal instrCache_data : Instr_cache_data;
	signal instrCache_addr : Instr_Cahce_addr;

	signal clk, reset, jump : std_ulogic;
begin
	instructionCache : Instruction_Cache
		generic map ("testInstrukcije.txt")
		port map(out_data => instrCache_data,
				in_addr => instrCache_addr,
				in_load => reset);
	uut : CPU
		port map(
			clk => clk, reset => reset,
			in_instr_cache_data => instrCache_data,
			out_instr_cache_addr => instrCache_addr);
	
	process
	begin
		clk <= '0'; wait for 5 ns;
		clk <= '1'; wait for 5 ns;
	end process;

	process
	begin
		reset <= '1';
		jump <= '0';

		wait for 10 ns;
		reset <= '0';

		wait;
	end process;
end architecture;