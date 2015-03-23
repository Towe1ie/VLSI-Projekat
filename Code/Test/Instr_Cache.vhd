library ieee;
library work;
library std;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.Declarations.all;
use work.Functions.all;

entity Instruction_Cache is
	generic
	(
		loadFileName : string := "memory.bin"
	);
	port
	(
		out_data : out Instr_Cache_data;
		in_addr : in Instr_Cahce_addr;

		in_load : in std_logic
	);
end entity;

architecture Instruction_Cache_arch of Instruction_Cache is
	type Regs is array (0 to 2**OM_ADDR_SIZE - 1) of Word;

	signal readWord : Word;
	signal memory : Regs;
	signal initPC : OM_Addr;
begin
	out_data.data1 <= memory(to_integer(in_addr.addr1));
	out_data.data2 <= memory(to_integer(in_addr.addr2));
	out_data.initPC <= initPC;
	
	process (in_load)
		file loadFile : TEXT open read_mode is loadFileName;
		variable addrInt : natural;
		variable addr : Word;
		variable word : Word;
		variable l : line;
		variable good, pcInitialized : boolean;
	begin
		if (in_load = '1')
		then
			pcInitialized := false;
			while not endfile(loadFile)
			loop
				readline(loadFile, l);
				hread(l, addr, good);
				if (not pcInitialized)
				then
				  initPC <= addr(OM_ADDR_SIZE - 1 downto 0);
				  pcInitialized := true;
				end if;
				read(l, word, good);
				addrInt := to_integer(addr);
				memory(addrInt) <= word;
			end loop;
		end if;
	end process;
end architecture;