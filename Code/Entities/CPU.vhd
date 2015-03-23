library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Components.all;
use work.Declarations.all;

entity CPU is
	port
	(
		in_instr_cache_data : in Instr_Cache_data;
		out_instr_cache_addr : out Instr_Cahce_addr;

		clk, reset : in std_ulogic
	);
end entity;

architecture CPU_arch of CPU is
	signal IF_ID_out_signal : IF_ID_out;
	signal ID_IF_out_signal : ID_IF_out;

	signal flush : std_ulogic;
begin
	flush <= '0';
	IFStage : IF_Stage
		generic map(1)
		port map
		(
			in_instr_cache_data => in_instr_cache_data,
			out_instr_cache_addr => out_instr_cache_addr,
			in_id_stage => ID_IF_out_signal,
			out_id_stage => IF_ID_out_signal,
			jump => '0',
			reset => reset,
			clk => clk
		);

	IDStage : ID_Stage
		port map(
			out_if_stage => ID_IF_out_signal,
			in_if_stage => IF_ID_out_signal,
			first => open,
			second => open,
			clk => clk,
			reset => reset,
			flush => flush);

end architecture;