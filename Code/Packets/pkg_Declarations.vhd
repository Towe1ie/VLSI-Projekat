library ieee;

use ieee.std_logic_1164.all;

package Declarations is
	constant OM_ADDR_SIZE : natural := 8;
	subtype OM_Addr is std_ulogic_vector(OM_ADDR_SIZE - 1 downto 0);

	constant WORD_SIZE : natural := 32;
	subtype Word is std_ulogic_vector(WORD_SIZE - 1 downto 0);

-- **** Caches ****
	type Instr_Cache_data is record
		data1, data2 : Word;
		initPC : OM_Addr;
	end record;

	type Instr_Cahce_addr is record
		addr1, addr2 : OM_Addr;
	end record;

-- **** IF/ID ****
	constant IF_ID_BUFFER_ADDR_SIZE : natural := 2;
	type IF_ID_out is record
		put2 : std_ulogic;
		instr1, instr2 : Word;
	end record;

	type ID_IF_out is record
		free2 : std_ulogic;
	end record;
end package;