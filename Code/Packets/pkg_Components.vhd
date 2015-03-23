library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;

package Components is
	component CPU is
		port
		(
			in_instr_cache_data : in Instr_Cache_data;
			out_instr_cache_addr : out Instr_Cahce_addr;

			clk, reset : in std_ulogic
		);
	end component;
	component IF_Stage is
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

			jump, reset, clk : in std_ulogic
		);
	end component;

	component ID_Stage is
		port
		(
			out_if_stage : out ID_IF_out;
			in_if_stage : in IF_ID_out;

			first, second : out Word;

			clk, reset, flush : std_ulogic
		);
	end component;

	component Instruction_Cache is
		generic
		(
			loadFileName : string := "memory.txt"
		);
		port
		(
			out_data : out Instr_Cache_data;
			in_addr : in Instr_Cahce_addr;

			in_load : in std_logic
		);
	end component;

	component FIFO_Controler is
		generic
		(
			addr_size : natural := 4
		);
		port
		(
			tail, head : out std_ulogic_vector(addr_size - 1 downto 0);
			full, empty, free2, have2: out std_ulogic;
			wr1, wr2 : out std_ulogic;
			put1, put2, take1, take2 : in std_ulogic;
			reset : in std_ulogic;
			clk : in std_ulogic
		);
	end component;
end package;