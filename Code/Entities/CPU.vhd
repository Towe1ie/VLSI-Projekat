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

	signal CSR_reg, CSR_next, CSR_in : Word;
	signal wr_CSR : std_ulogic;

	signal alu1_instr, alu2_instr : Decoded_Instruction;
	signal res1, res2 : Word;
	signal WB_data_hazard_control_signal : WB_Data_Hazard_Control;
	signal EXE_data_hazard_control_signal : EXE_Data_Hazard_Control;

	signal alu1_WB_signal, alu2_WB_signal : ALU_WB_out;
	signal WB_GPR_signal : WB_GPR_out;

	signal flush : std_ulogic;
begin
-- **** Concurent ****
	flush <= '0';
	CSR_in <= (others => '0');

-- **** CSR Process ****
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

-- **** GPR ****
	GPR : GPRFile
		generic map(GPR_ADDR_SIZE, WORD_SIZE)
		port map(
			in_wb => WB_GPR_signal,
			in_id_address => ID_GPR_addr_signal,
			out_id_data => GPR_ID_data_signal,
			clk => clk,
			reset => reset);

-- **** IF Stage ****
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

-- **** ID Stage ****
	IDStage : ID_Stage
		port map(
			out_if_stage => ID_IF_out_signal,
			in_if_stage => IF_ID_out_signal,
			out_GPR_addr => ID_GPR_addr_signal,
			in_GPR_data => GPR_ID_data_signal,
			in_CSR => CSR_reg,
			in_WB_data_hazard_control => WB_data_hazard_control_signal,
			in_EXE_data_hazard_control => EXE_data_hazard_control_signal,			
			first_instr => alu1_instr,
			second_instr => alu2_instr,
			clk => clk,
			reset => reset,
			flush => flush);

-- **** EXE Stage ****
	ALU_1 : ALU
		port map(
			in_instr => alu1_instr,
			out_data_hazard_info => EXE_data_hazard_control_signal.alu1_info,
			out_wb => alu1_WB_signal,
			clk => clk,
			flush => flush,
			reset => reset
			);

	ALU_2 : ALU
		port map(
			in_instr => alu2_instr,
			out_data_hazard_info => EXE_data_hazard_control_signal.alu2_info,
			out_wb => alu2_WB_signal,
			clk => clk,
			flush => flush,
			reset => reset
			);

-- **** WB Stage ****
	WBStage : WB_Stage
		port map(
			in_alu1 => alu1_WB_signal,
			in_alu2 => alu2_WB_signal,
			out_data_hazard_control => WB_data_hazard_control_signal,
			out_GPR => WB_GPR_signal,
			clk => clk,
			flush => flush,
			reset => reset
			);
end architecture;