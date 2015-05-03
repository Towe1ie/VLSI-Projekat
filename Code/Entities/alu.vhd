library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;
use work.DecodeFunctions.all;
use work.Functions.all;

entity ALU is
	port
	(
		in_instr : in Decoded_Instruction;

		out_data_hazard_info : out Data_hazard_info;
		out_WB : out WB_Reg_Instr;

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
	signal pc_reg, pc_next : OM_Addr;

	signal a_c, b_c, imm_c, result_c : std_ulogic_vector(WORD_SIZE downto 0); -- Signali prosireni za jedan bit tako da ukljuce i carry
	signal asr_res : std_ulogic_vector(WORD_SIZE downto 0);
	signal C : std_ulogic;
	signal newC, newN, newZ, newV : std_ulogic;
	signal newCSR : Word;
	signal set_C, set_V, set_N : std_ulogic;

	signal working : std_ulogic;

	signal result : Word;
begin
	process(clk, flush, reset)
	begin
		if (flush = '1' or reset = '1')
		then
			ready_reg <= '0';
		elsif (rising_edge(clk))
		then
			op_reg <= op_next;
			a_reg <= a_next;
			b_reg <= b_next;
			CSR_reg <= CSR_next;
			dst_reg <= dst_next;
			imm_reg <= imm_next;
			ready_reg <= ready_next;
			pc_reg <= pc_next;
		end if;
	end process;

	op_next		<= in_instr.info.op;
	a_next		<= in_instr.src1_Value;
	b_next		<= in_instr.src2_Value;
	CSR_next	<= in_instr.CSR;
	imm_next	<= in_instr.info.imm;
	dst_next	<= in_instr.info.dst_addr;
	ready_next 	<= in_instr.ready;
	pc_next		<= in_instr.info.pc;

	a_c(WORD_SIZE) <= '0';
	a_c(WORD_SIZE - 1 downto 0) <= a_reg;
	b_c(WORD_SIZE) <= '0';
	b_c(WORD_SIZE - 1 downto 0) <= b_reg;
	imm_c(WORD_SIZE) <= '0';
	imm_c(WORD_SIZE - 1 downto 0) <= imm_reg;

	C <= CSR_reg(C_POS);

	result_c <= a_c and b_c 	when op_reg = AND_I else
				a_c - b_c 		when op_reg = SUB_I else
				a_c + b_c		when op_reg = ADD_I else
				a_c + b_c + C 	when op_reg = ADC_I else
				a_c - b_c - C 	when op_reg = SBC_I else
				a_c - b_c 		when op_reg = CMP_I else
				a_c - b_c 		when op_reg = SSUB_I else
				a_c + b_c 		when op_reg = SADD_I else
				a_c + b_c + C 	when op_reg = SADC_I else
				a_c - b_c - C 	when op_reg = SSBC_I else
				b_c				when op_reg = MOV_I else
				not b_c 		when op_reg = NOT_I else
				lsl(b_c, a_c)	when op_reg = SL_I else
				lsr(b_c, a_c) 	when op_reg = SR_I else
				asr_res		 	when op_reg = ASR_I else
				imm_c			when op_reg = MOV_IMM_I else
				imm_c 			when op_reg = SMOV_IMM_I else
				(others => 'X');

	asr_res(WORD_SIZE - 1 downto 0) <= asr(b_reg, a_reg);
	asr_res(WORD_SIZE) <= '0';
	
-- **** Nove vrednosti CSR bitova ****
	newN <= result_c(WORD_SIZE - 1);
	newC <= result_c(WORD_SIZE);
	newV <= '1' when ((op_reg = SADD_I or op_reg = SADC_I) and (a_c(WORD_SIZE - 1) = b_c(WORD_SIZE - 1)) and (result_c(WORD_SIZE - 1) /= a_c(WORD_SIZE - 1))) or
					 ((op_reg = SSUB_I or op_reg = SSBC_I) and (a_c(WORD_SIZE - 1) /= b_c(WORD_SIZE - 1)) and (result_c(WORD_SIZE - 1) /= a_c(WORD_SIZE - 1))) else
			'0';
	newZ <= '1' when result = 0 else
			'0';
-- **** Provera koje CSR bitove je potrebno postaviti ****
	set_C <= newC when op_reg = SUB_I or op_reg = ADD_I or op_reg = ADC_I or op_reg = SBC_I else
			'0'; 
	set_V <= newV when op_reg = SSUB_I or op_reg = SADD_I or op_reg = SADD_I or op_reg = SSBC_I else
			'0';
	set_N <= newV when op_reg = SSUB_I or op_reg = SADD_I or op_reg = SADD_I or op_reg = SSBC_I or op_reg = ASR_I or op_reg = CMP_I else
			'0';

	newCSR(N_POS) <= newN when set_N = '1' else
					'0';
	newCSR(Z_POS) <= newZ;
	newCSR(V_POS) <= newV when set_V = '1' else
					'0';
	newCSR(C_POS) <= newC when set_C = '1' else
					'0';
	newCSR(27 downto 0) <= (others => '0');

	working <= 	'1' when get_instr_type(op_reg) = ALU_Type and ready_reg = '1' else
				'0';

	result <= result_c(WORD_SIZE - 1 downto 0);

	out_data_hazard_info.dst 	<= dst_reg;
	out_data_hazard_info.valid 	<= working;
	out_data_hazard_info.value 	<= result;
	out_data_hazard_info.CSR 	<= newCSR;
	out_data_hazard_info.updateCSR <= '1';
	out_data_hazard_info.canForward <= '1';
	out_data_hazard_info.elapsedTime <= 0;

	out_WB.value <= result;
	out_WB.op 	<= op_reg;
	out_WB.dst 	<= dst_reg;
	out_WB.valid <= working;
	out_WB.CSR 	<= newCSR;
	out_WB.updateCSR <= '1';
	out_WB.cnd <= 'U';
	out_WB.jmp_addr <= (others => 'U');
	out_WB.pc <= pc_reg;

end architecture;