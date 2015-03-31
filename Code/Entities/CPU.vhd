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

	signal ID_GPR_addr_signal : ID_GPR_addr;
	signal GPR_ID_data_signal : GPR_ID_data;
	signal wr_GPR_signal : std_ulogic;
	signal GPR_data_in_signal : Word;
	signal GPR_wraddr_signal : GPR_addr;

	signal CSR_reg, CSR_next, CSR_in : Word;
	signal wr_CSR : std_ulogic;

	signal flush : std_ulogic;
begin
	flush <= '0';
	wr_GPR_signal <= '0';
	GPR_data_in_signal <= (others => '0');
	GPR_wraddr_signal <= (others => '0');
	CSR_in <= (others => '0');

	process(clk, reset)
	begin
		if (rising_edge(clk))
		then
			if (reset = '1')
			then
				CSR_reg <= (others => '0');
			else
				CSR_reg <= CSR_next;
			end if;
		end if;
	end process;
	
	wr_CSR <= '0';
	CSR_next <= CSR_in when wr_CSR = '1' else
				CSR_reg;

	GPR : GPRFile
		generic map(GPR_ADDR_SIZE, WORD_SIZE)
		port map(
			wrAddr => GPR_wraddr_signal,
			dataIn => GPR_data_in_signal,
			wr => wr_GPR_signal,
			in_id_address => ID_GPR_addr_signal,
			out_id_data => GPR_ID_data_signal,
			clk => clk,
			reset => reset);

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
			out_GPR_addr => ID_GPR_addr_signal,
			in_GPR_data => GPR_ID_data_signal,
			in_CSR => CSR_reg,
			first_instr => open,
			second_instr => open,
			clk => clk,
			reset => reset,
			flush => flush);

end architecture;