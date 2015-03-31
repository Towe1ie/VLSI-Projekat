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
		wrAddr : in GPR_addr;
		dataIn : in Word;
		wr : in std_ulogic;
		
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
	
	process(wr, dataIn, wrAddr, regs)
		variable i1, i2 : integer;
	begin
		i1 := to_integer(wrAddr);
		
		for i in regs_next'range
		loop
			regs_next(i) <= regs(i);
		end loop;
		
		if (wr = '1')
		then
			regs_next(i1) <= dataIn;
		end if;
	end process;
end architecture;