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

		in_data_cache : in Data_Cache_out;
		out_data_cache : out Data_Cache_in;

		clk, reset : in std_ulogic
	);
end entity;

architecture CPU_arch of CPU is
	signal IF_ID_out_signal : IF_ID_out;
	signal ID_IF_out_signal : ID_IF_out;

	signal ID_GPR_addr_signal : ID_GPR_addr;
	signal GPR_ID_data_signal : GPR_ID_data;

	signal CSR_reg, CSR_next, CSR_in : Word;
	signal WB_CSR_signal : WB_CSR_out;

	signal first_instr, second_instr : Decoded_Instruction;
	signal res1, res2 : Word;
	signal WB_data_hazard_control_signal : WB_Data_Hazard_Control;
	signal EXE_data_hazard_control_signal : EXE_Data_Hazard_Control;

	signal loadStore_busy, branch_busy : std_ulogic;

	signal alu1_WB_signal, alu2_WB_signal, br_WB_signal, loadStore_WB_signal : WB_Reg_Instr;
	signal WB_GPR_signal : WB_GPR_out;

	signal jumpAddr : OM_Addr;
	signal flush : std_ulogic;
begin
-- **** Concurent ****

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
	
	CSR_next <= WB_CSR_signal.CSR when WB_CSR_signal.wrCSR = '1' else
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
			jumpAddr => jumpAddr,
			jump => flush,
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
			in_loadStoreBusy => loadStore_busy,
			in_branch_busy => branch_busy,
			first_instr => first_instr,
			second_instr => second_instr,
			clk => clk,
			reset => reset,
			flush => flush);

-- **** EXE Stage ****
	ALU_1_Unit : ALU
		port map(
			in_instr => first_instr,
			out_data_hazard_info => EXE_data_hazard_control_signal.alu1_info,
			out_wb => alu1_WB_signal,
			clk => clk,
			flush => flush,
			reset => reset);

	ALU_2_Unit : ALU
		port map(
			in_instr => second_instr,
			out_data_hazard_info => EXE_data_hazard_control_signal.alu2_info,
			out_wb => alu2_WB_signal,
			clk => clk,
			flush => flush,
			reset => reset);

	Branch_Unit : Branch
		port map(
			in_instr_first => first_instr,
			in_instr_second => second_instr,
			out_WB => br_WB_signal,
			out_busy => branch_busy,
			clk => clk,
			flush => flush,
			reset => reset);

	LOAD_STORE_UNIT : Load_Store
		generic map(DATA_CACHE_DELAY)
		port map(
			in_instr_first => first_instr,
			in_instr_second => second_instr,
			dcache_in => in_data_cache,
			dcache_out => out_data_cache,
			out_data_hazard_info => EXE_Data_Hazard_Control_signal.load_Store_info,
			out_busy => loadStore_busy,
			out_WB => loadStore_WB_signal,
			clk => clk,
			flush => flush,
			reset => reset);

-- **** WB Stage ****
	WBStage : WB_Stage
		port map(
			in_alu1 => alu1_WB_signal,
			in_alu2 => alu2_WB_signal,
			in_br => br_WB_signal,
			in_loadStore => loadStore_WB_signal,
			out_data_hazard_control => WB_data_hazard_control_signal,
			out_CSR => WB_CSR_signal,
			out_flush => flush,
			out_jumpAddr => jumpAddr,
			out_GPR => WB_GPR_signal,
			clk => clk,
			reset => reset
			);
end architecture;