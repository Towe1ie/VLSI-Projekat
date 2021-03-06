library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;
use work.Functions.all;

entity WB_Stage is
	port
	(
		in_alu1, in_alu2, in_br, in_loadStore : in WB_Reg_Instr;

		out_data_hazard_control : out WB_Data_Hazard_Control;
		out_GPR : out WB_GPR_out;

		out_CSR : out WB_CSR_out;

		out_flush : out std_ulogic;
		out_jumpAddr : out OM_Addr;

		clk, reset : in std_ulogic
	);
end entity;

architecture WB_Stage_arch of WB_Stage is 
	signal alu1_reg, alu1_next, alu2_reg, alu2_next, br_reg, br_next, loadStore_reg, loadStore_next : WB_Reg_Instr;
	signal jump : std_ulogic;
begin
	process(clk)
	begin
		if (rising_edge(clk))
		then
			if (reset = '1' or jump = '1')
			then
				alu1_reg.valid <= '0';
				alu2_reg.valid <= '0';
				br_reg.valid <= '0';
				loadStore_reg.valid <= '0';
			else
				alu1_reg <= alu1_next;
				alu2_reg <= alu2_next;
				br_reg <= br_next;
				loadStore_reg <= loadStore_next;
			end if;
		end if;
	end process;

	out_data_hazard_control.alu1_info.valid <= alu1_reg.valid;
	out_data_hazard_control.alu1_info.dst <= alu1_reg.dst;
	out_data_hazard_control.alu1_info.canForward <= '1';
	out_data_hazard_control.alu1_info.value <= alu1_reg.value;
	out_data_hazard_control.alu1_info.CSR <= alu1_reg.CSR;
	out_data_hazard_control.alu1_info.updateCSR <= alu1_reg.updateCSR;
	out_data_hazard_control.alu1_info.elapsedTime <= 0;

	out_data_hazard_control.alu2_info.valid <= alu2_reg.valid;
	out_data_hazard_control.alu2_info.dst <= alu2_reg.dst;
	out_data_hazard_control.alu2_info.canForward <= '1';
	out_data_hazard_control.alu2_info.value <= alu2_reg.value;
	out_data_hazard_control.alu2_info.CSR <= alu2_reg.CSR;
	out_data_hazard_control.alu2_info.updateCSR <= alu2_reg.updateCSR;
	out_data_hazard_control.alu2_info.elapsedTime <= 0;

	out_data_hazard_control.loadStore_info.valid <= loadStore_reg.valid;
	out_data_hazard_control.loadStore_info.dst <= loadStore_reg.dst;
	out_data_hazard_control.loadStore_info.canForward <= '1';
	out_data_hazard_control.loadStore_info.value <= loadStore_reg.value;
	out_data_hazard_control.loadStore_info.CSR <= (others => 'X');
	out_data_hazard_control.loadStore_info.updateCSR <= '0';
	out_data_hazard_control.loadStore_info.elapsedTime <= 0;

	alu1_next <= in_alu1;
	alu2_next <= in_alu2;
	br_next <= in_br;
	loadStore_next <= in_loadStore;

	out_GPR.wrAlu1 <= 	'1' when alu1_reg.valid = '1' and alu1_reg.op /= CMP_I else
						'0';
	out_GPR.alu1_addr <= alu1_reg.dst;
	out_GPR.alu1_value <= alu1_reg.value;

	out_GPR.wrAlu2 <= 	'1' when alu2_reg.valid = '1' and alu2_reg.op /= CMP_I and jump = '0' else
						'0';
	out_GPR.alu2_addr <= alu2_reg.dst;
	out_GPR.alu2_value <= alu2_reg.value;

	out_GPR.wrLoadStore <= 	'1' when loadStore_reg.valid = '1' and loadStore_reg.op = LOAD_I else
							'0';
	out_GPR.loadStore_addr <= loadStore_reg.dst;
	out_GPR.loadStore_value <= loadStore_reg.value;

	out_GPR.wrBr <= '1' when br_reg.valid = '1' and br_reg.op = BLAL_I else
					'0';
	out_GPR.br_addr <= br_reg.dst;
	out_GPR.br_value <= to_std_ulogic_vector(to_integer_unsigned(br_reg.pc) + 1, WORD_SIZE);

	jump <= br_reg.valid and br_reg.cnd;
	out_flush <= jump;
	out_jumpAddr <= br_reg.jmp_addr;

	process(alu1_reg, alu2_reg)
	begin
		out_CSR.wrCSR <= '0';
		out_CSR.CSR <= (others => 'X');
		if (alu1_reg.updateCSR = '1' and alu1_reg.valid = '1')
		then
			out_CSR.wrCSR <= '1';
			out_CSR.CSR <= alu1_reg.CSR;
		end if;

		if (alu2_reg.updateCSR = '1' and alu2_reg.valid = '1')
		then
			out_CSR.wrCSR <= '1';
			out_CSR.CSR <= alu2_reg.CSR;
		end if;
	end process;
end architecture;