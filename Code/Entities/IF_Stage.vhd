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
		jump, reset, clk : in std_ulogic;
		some_output : out OM_Addr_t
	);

end entity;

architecture IF_Stage_arch of IF_Stage is
	signal pc_reg, pc_next : OM_Addr_t;
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
					pc_reg <= (others => '0'); -- upisati podatak u pocetnoj adresi programa
				else
					pc_reg <= (others => '0'); -- upisati adresu skoka
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
	
	pc_next <= pc_reg + 2;
	
	some_output <= pc_reg;
end architecture;