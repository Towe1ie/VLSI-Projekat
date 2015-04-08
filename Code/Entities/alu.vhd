library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;
use work.DecodeFunctions.all;

entity ALU is
	port
	(
		in_instr : in Decoded_Instruction;

		out_data_hazard_info : out Data_hazard_info;
		out_WB : out ALU_WB_out;

		clk, flush, reset : std_ulogic
	);
end entity;

architecture ALU_arch of ALU is
	signal op_reg, op_next : Mnemonic;
	signal a_reg, a_next, b_reg, b_next : Word;
	signal imm_reg, imm_next : Word;
	signal CSR_reg, CSR_next : Word;
	signal dst_reg, dst_next : GPR_addr;
	signal ready_reg, ready_next : std_ulogic;

	signal working : std_ulogic;

	signal result : Word;
begin
	process(clk)
	begin
		if (rising_edge(clk))
		then
			op_reg <= op_next;
			a_reg <= a_next;
			b_reg <= b_next;
			CSR_reg <= CSR_next;
			dst_reg <= dst_next;
			imm_reg <= imm_next;
			ready_reg <= ready_next;
		end if;
	end process;

	op_next		<= 	--op_reg when in_ID_stage.start = '0' else
					in_instr.info.op;
	a_next		<= 	--a_reg when in_ID_stage.start = '0' else
					in_instr.src1_Value;
	b_next		<= 	--b_reg when in_ID_stage.start = '0' else
					in_instr.src2_Value;
	CSR_next	<= 	--CSR_reg when in_ID_stage.start = '0' else
					in_instr.CSR;
	imm_next	<= 	--imm_reg when in_ID_stage.start = '0' else
					in_instr.info.imm;
	dst_next	<= 	--dst_reg when in_ID_stage.start = '0' else
					in_instr.info.dst_addr;
	ready_next <= in_instr.ready;


	working <= 	'1' when get_instr_type(op_reg) = ALU_Type and ready_reg = '1' else
				'0';

	result <= imm_reg;

	out_data_hazard_info.dst 	<= 	dst_reg;
	out_data_hazard_info.valid 	<=	working;
	out_data_hazard_info.value <= result;
	out_data_hazard_info.canForward <= '1';

	out_WB.instr_info.value <= result;
	out_WB.instr_info.op <= op_reg;
	out_WB.instr_info.dst <= dst_reg;
	out_WB.instr_info.valid <= working;

end architecture;