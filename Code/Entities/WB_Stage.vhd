library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;

entity WB_Stage is
	port
	(
		in_alu1, in_alu2 : in ALU_WB_out;

		out_data_hazard_control : out WB_Data_Hazard_Control;
		out_GPR : out WB_GPR_out;

		out_CSR : out WB_CSR_out;

		clk, flush, reset : in std_ulogic
	);
end entity;

architecture WB_Stage_arch of WB_Stage is 
	signal alu1_reg, alu1_next, alu2_reg, alu2_next : WB_Reg_Instr;
begin
	process(clk)
	begin
		if (rising_edge(clk))
		then
			if (reset = '1' or flush = '1')
			then
				alu1_reg.valid <= '0';
				alu2_reg.valid <= '0';
			else
				alu1_reg <= alu1_next;
				alu2_reg <= alu2_next;
			end if;
		end if;
	end process;

	out_data_hazard_control.alu1_info.valid <= alu1_reg.valid;
	out_data_hazard_control.alu1_info.dst <= alu1_reg.dst;
	out_data_hazard_control.alu1_info.canForward <= '1';
	out_data_hazard_control.alu1_info.value <= alu1_reg.value;
	out_data_hazard_control.alu1_info.CSR <= alu1_reg.CSR;
	out_data_hazard_control.alu1_info.updateCSR <= alu1_reg.updateCSR;

	out_data_hazard_control.alu2_info.valid <= alu2_reg.valid;
	out_data_hazard_control.alu2_info.dst <= alu2_reg.dst;
	out_data_hazard_control.alu2_info.canForward <= '1';
	out_data_hazard_control.alu2_info.value <= alu2_reg.value;
	out_data_hazard_control.alu2_info.CSR <= alu2_reg.CSR;
	out_data_hazard_control.alu2_info.updateCSR <= alu2_reg.updateCSR;

	out_data_hazard_control.loadStore_info.valid <= '0';
	out_data_hazard_control.loadStore_info.dst <= (others => '0');
	out_data_hazard_control.loadStore_info.canForward <= '0';
	out_data_hazard_control.loadStore_info.value <= (others => '0');
	out_data_hazard_control.loadStore_info.CSR <= (others => '0');
	out_data_hazard_control.loadStore_info.updateCSR <= '0';

	alu1_next <= 	in_alu1.instr_info;-- when in_alu1.put = '1' else
					--alu1_reg;
	alu2_next <= 	in_alu2.instr_info;-- when in_alu2.put = '1' else
					--alu2_reg;

	out_GPR.wrAlu1 <= 	'1' when alu1_reg.valid = '1' else
						'0';
	out_GPR.alu1_addr <= alu1_reg.dst;
	out_GPR.alu1_value <= alu1_reg.value;

	out_GPR.wrAlu2 <= 	'1' when alu2_reg.valid = '1' else
						'0';
	out_GPR.alu2_addr <= alu2_reg.dst;
	out_GPR.alu2_value <= alu2_reg.value;

	out_GPR.wrLoadStore <= '0'; -- Privremeno
	out_GPR.loadStore_addr <= (others => '0');
	out_GPR.loadStore_value <= (others => '1');

	process(alu1_reg, alu2_reg)
	begin
		out_CSR.wrCSR <= '0';
		out_CSR.CSR <= (others => 'X');
		if (alu1_reg.updateCSR = '1')
		then
			out_CSR.wrCSR <= '1';
			out_CSR.CSR <= alu1_reg.CSR;
		end if;

		if (alu2_reg.updateCSR = '1')
		then
			out_CSR.wrCSR <= '1';
			out_CSR.CSR <= alu2_reg.CSR;
		end if;
	end process;
end architecture;