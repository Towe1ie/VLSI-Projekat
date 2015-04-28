library ieee;
library work;

use work.Declarations.all;
use work.Functions.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.all;


entity IF_Stage is
	generic
	(
		INSTR_CACHE_DELAY : natural := 1
	);
	port
	(
		in_instr_cache_data : in Instr_Cache_data;
		out_instr_cache_addr : out Instr_Cahce_addr;

		in_id_stage : in ID_IF_out;
		out_id_stage : out IF_ID_out;

		jumpAddr : in OM_Addr;
		jump, reset, clk : in std_ulogic

	);
end entity;

architecture IF_Stage_arch of IF_Stage is
	signal pc_reg, pc_next : OM_Addr;
	signal instrCache_delay : natural;
begin
	process(clk)
	begin
		if (rising_edge(clk))
		then
			if (reset = '1' or jump = '1')
			then
				instrCache_delay <= INSTR_CACHE_DELAY;
				if (reset = '1')
				then
					pc_reg <= in_instr_cache_data.initPC;
				else
					pc_reg <= jumpAddr;
				end if;
			else
				pc_reg <= pc_next;
				if (instrCache_delay /= 0)
				then
					instrCache_delay <= instrCache_delay - 1;
				end if;
			end if;
		end if;
	end process;
	
	pc_next <= 	pc_reg + 2 when in_id_stage.free2 = '1' else
				pc_reg;
	
	out_instr_cache_addr.addr1 <= pc_reg;
	out_instr_cache_addr.addr2 <= pc_reg + 1;

	out_id_stage.instr1.raw_instr <= in_instr_cache_data.data1;
	out_id_stage.instr1.pc <= pc_reg;
	out_id_stage.instr2.raw_instr <= in_instr_cache_data.data2;
	out_id_stage.instr2.pc <= pc_reg + 1;
	out_id_stage.put2	<=	'1' when in_id_stage.free2 = '1' else
							'0';

end architecture;