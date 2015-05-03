library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Declarations.all;
use work.Functions.all;
use work.DecodeFunctions.all;

entity Branch is
	port
	(
		in_instr_first, in_instr_second : in Decoded_Instruction;

		out_WB : out WB_Reg_Instr;
		out_busy : out std_ulogic;

		clk, flush, reset : std_ulogic
	);
end entity;

architecture Branch_arch of Branch is
	signal op_reg, op_next : Mnemonic;
	signal CSR_reg, CSR_next : Word;
	signal offset_reg, offset_next : Word;
	signal pc_reg, pc_next : OM_Addr;
	signal ready_reg, ready_next : std_ulogic;

	signal in_instr : Decoded_Instruction;

	signal jmp_addr : OM_Addr;
	signal working : std_ulogic;
	signal cnd : std_ulogic;
begin
	process(clk, flush, reset)
	begin
		if (flush = '1' or reset = '1')
		then
			ready_reg <= '0';
		elsif (rising_edge(clk))
		then
			op_reg <= op_next;
			CSR_reg <= CSR_next;
			offset_reg <= offset_next;
			ready_reg <= ready_next;
			pc_reg <= pc_next;
		end if;
	end process;

	in_instr 	<= 	in_instr_first when in_instr_first.ready = '1' else
					in_instr_second;

	op_next		<= in_instr.info.op;
	CSR_next	<= in_instr.CSR;
	offset_next	<= in_instr.info.jmp_offset;
	ready_next 	<= in_instr.ready;
	pc_next		<= in_instr.info.pc;

	jmp_addr	<= to_std_ulogic_vector(to_integer_unsigned(pc_reg) + to_integer_signed(offset_reg) + 1, OM_ADDR_SIZE);
	working 	<= 	'1' when get_instr_type(op_reg) = BRANCH_Type and ready_reg = '1' else
					'0';

	cnd <= 	'1' when (op_reg = BEQ_I and CSR_reg(Z_pos) = '1') or
				(op_reg = BGT_I and  (((CSR_reg(N_pos) xor CSR_reg(V_POS)) or CSR_reg(Z_POS)) = '0')) or
				(op_reg = BHI_I and (CSR_reg(C_pos) or CSR_reg(Z_pos)) = '0') or
				(op_reg = BAL_I) or
				(op_reg = BLAL_I) else
	   		'0';

	out_WB.value <= (others => 'U');
	out_WB.op 	<= op_reg;
	out_WB.dst 	<= to_std_ulogic_vector(LINK_REG_DST, GPR_ADDR_SIZE);
	out_WB.valid <= working;
	out_WB.CSR 	<= CSR_reg;
	out_WB.updateCSR <= '0';
	out_WB.cnd <= cnd;
	out_WB.jmp_addr <= jmp_addr;
	out_WB.pc <= pc_reg;

	out_busy <= working;
end architecture;