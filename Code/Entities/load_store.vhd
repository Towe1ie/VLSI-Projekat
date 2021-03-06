library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;
use work.DecodeFunctions.all;

entity Load_Store is 
	generic
	(
		dataCache_delay : natural := 3
	);
	port
	(
		in_instr_first, in_instr_second : in Decoded_Instruction;

		dcache_in : in Data_Cache_out;
		dcache_out : out Data_Cache_in;

		out_data_hazard_info : out Data_hazard_info;

		out_busy : out std_ulogic;
		out_WB : out WB_Reg_Instr;

		clk, flush, reset : std_ulogic
	);
end entity;

architecture Load_Store_arch of Load_Store is
	signal op_reg, op_next : Mnemonic;
	signal pc_reg, pc_next : OM_Addr;
	signal dst_reg, dst_next : GPR_addr;
	signal mem_addr_reg, mem_addr_next : OM_Addr;
	signal wr_value_reg, wr_value_next : Word;
	signal ready_reg, ready_next : std_ulogic;
	signal cnt_reg, cnt_next : natural;

	signal in_instr : Decoded_Instruction;
	signal working, busy : std_ulogic;
begin

	process(clk, flush, reset)
	begin
		if (rising_edge(clk))
		then
			if (reset = '1' or flush = '1')
			then
				ready_reg <= '0';
			else
				op_reg <= op_next;
				pc_reg <= pc_next;
				mem_addr_reg <= mem_addr_next;
				wr_value_reg <= wr_value_next;
				ready_reg <= ready_next;
				dst_reg <= dst_next;
				cnt_reg <= cnt_next;
			end if;
		end if;
	end process;

	working <= 	'1' when ready_reg = '1' and get_instr_type(op_reg) = LOAD_STORE_Type else
				'0';
	busy <= '1' when working = '1' and cnt_reg < dataCache_delay else
			'0';

	in_instr <= in_instr_first when in_instr_first.ready = '1' and get_instr_type(in_instr_first.info.op) = LOAD_STORE_Type else
				in_instr_second;

	op_next <= 	in_instr.info.op when busy = '0' else
				op_reg;
	pc_next	<=	in_instr.info.pc when busy = '0' else
				pc_reg;
	dst_next <=	in_instr.info.dst_addr when busy = '0' else
				dst_reg;
	mem_addr_next <= in_instr.src1_Value(OM_ADDR_SIZE - 1 downto 0) when busy = '0' else
					mem_addr_reg;
	wr_value_next	<= 	in_instr.src2_Value when busy = '0' else
					wr_value_reg;
	ready_next	<= 	in_instr.ready when busy = '0' else
					ready_reg;
	cnt_next 	<= 	0 when busy = '0' else
					cnt_reg + 1 when busy = '1' else
					cnt_reg;

	dcache_out.wr <= '1' when op_reg = STORE_I and busy = '1' else
					 '0';
	dcache_out.rd <= '1' when op_reg = LOAD_I and busy = '1' else
					 '0';
	dcache_out.data_in <= wr_value_reg;
	dcache_out.addr <= mem_addr_reg;

	out_WB.value <= dcache_in.data_out;
	out_WB.op <= op_reg;
	out_WB.dst <= dst_reg;
	out_wb.valid <= working and not busy;
	out_wb.CSR <= (others => 'X');
	out_wb.updateCSR <= '0';
	out_wb.cnd <= 'X';
	out_wb.jmp_addr <= (others => 'X');
	out_wb.pc <= pc_reg;

-- **** Data hazard signals ****
	out_data_hazard_info.dst <= dst_reg;
	out_data_hazard_info.valid <= working;
	out_data_hazard_info.value <= dcache_in.data_out;
	out_data_hazard_info.CSR <= (others => 'X');
	out_data_hazard_info.updateCSR <= '0';
	out_data_hazard_info.canForward <= 	'1' when cnt_reg = dataCache_delay else
										'0';
	out_data_hazard_info.elapsedTime <= cnt_reg;

	out_busy <= busy;
end architecture;