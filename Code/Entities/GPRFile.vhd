library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Declarations.all;
use work.Functions.all;

entity GPRFile is
	generic
	(
		addrSize : natural := 5;
		wordSize : natural := 32
	);
	port
	(
		in_wb : in WB_GPR_out;

		in_id_address : in ID_GPR_addr;
		out_id_data : out GPR_ID_data;
		
		clk, reset : in std_ulogic
	);
end entity;

architecture GPRFile_arch of GPRFile is
	type registerArray is array (0 to 2**addrSize - 1) of Word;
	signal regs, regs_next : registerArray;
begin
	out_id_data.dataOut1 <= regs(to_integer(in_id_address.addr1));
	out_id_data.dataOut2 <= regs(to_integer(in_id_address.addr2));
	out_id_data.dataOut3 <= regs(to_integer(in_id_address.addr3));
	out_id_data.dataOut4 <= regs(to_integer(in_id_address.addr4));

	process (clk, reset)
		variable i1, i2, iCDB : integer;
	begin
		if rising_edge(clk)
		then
			if (reset = '1')
			then
				for i in regs'range
				loop
					regs(i) <= (others => 'X');
				end loop;
			else
				for i in regs'range
				loop
					regs(i) <= regs_next(i);
				end loop;
			end if;
		end if;
	end process;
	
	process(in_wb, regs)
		variable i : integer;
	begin		
		for i in regs_next'range
		loop
			regs_next(i) <= regs(i);
		end loop;
		
		if (in_wb.wrLoadStore = '1')
		then
			i := to_integer(in_wb.loadStore_addr);
			regs_next(i) <= in_wb.loadStore_value;
		end if;

		if (in_wb.wrAlu1 = '1')
		then
			i := to_integer(in_wb.alu1_addr);
			regs_next(i) <= in_wb.alu1_value;
		end if;

		if (in_wb.wrAlu2 = '1')
		then
			i := to_integer(in_wb.alu2_addr);
			regs_next(i) <= in_wb.alu2_value;
		end if;
	end process;
end architecture;