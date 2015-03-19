library ieee;

use ieee.std_logic_1164.all;

package Declarations is
	constant OM_ADDR_SIZE : natural := 32;
	subtype OM_Addr_t is std_ulogic_vector(OM_ADDR_SIZE - 1 downto 0);
end package;