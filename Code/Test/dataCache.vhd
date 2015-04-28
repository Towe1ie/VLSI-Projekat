library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.Declarations.all;
use work.Functions.all;

entity Data_Cache is
	generic
	(
		loadFileName : string := "memory.bin";
		delay : natural := 0
	);
	port
	(
		dcache_in : in Data_Cache_in;
		dcache_out : out Data_Cache_out;

		clk : in std_logic;
		load : in std_logic
	);
end entity;

architecture Data_Cache_arch of Data_Cache is
	type registerArray is array (0 to 2**OM_ADDR_SIZE - 1) of Word;
	signal readWord : Word;
	signal regs, regs_next : registerArray;
	signal delayCnt_reg, delayCnt_next : natural;
begin
	dcache_out.data_out <= regs(to_integer_unsigned(dcache_in.addr)) when delayCnt_reg = 0 else
						  (others => 'X');
	
	delayCnt_next <= delayCnt_reg - 1 when delayCnt_reg /= 0 else
					 delay when (dcache_in.wr = '1' or dcache_in.rd = '1') and delayCnt_reg = 0 else
					 delayCnt_reg;

	process (load, clk)
		file loadFile : TEXT;
		variable i1 : natural;
		variable addr : Word;
		variable word : Word;
		variable l : line;
		variable good : boolean;
	begin
		if (load = '1')
		then
			file_open(loadFile, loadFileName, read_mode);
			i1 := 0;
			while not endfile(loadFile)
			loop
				readline(loadFile, l);
				hread(l, addr);
				read(l, word, good);
				regs(to_integer_unsigned(addr)) <= word;
				i1 := i1 + 1;
			end loop;
			file_close(loadFile);

			delayCnt_reg <= delay;
		elsif (rising_edge(clk))
		then
			for i in regs'range
			loop
				regs(i) <= regs_next(i);
			end loop;

			delayCnt_reg <= delayCnt_next;
		end if;
	end process;

	process(dcache_in, regs)
		variable addr : integer;
	begin
		addr := to_integer_unsigned(dcache_in.addr);
		
		for i in regs_next'range
		loop
			regs_next(i) <= regs(i);
		end loop;
		
		if (dcache_in.wr = '1')
		then
			regs_next(addr) <= dcache_in.data_in;
		end if;
	end process;
end architecture;