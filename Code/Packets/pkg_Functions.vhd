library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package Functions is
	function "+" (left, right : std_ulogic_vector) return std_ulogic_vector;
	function "+" (left : std_ulogic_vector; right : integer) return std_ulogic_vector;
end package;

package body Functions is
	function "+" (left, right : std_ulogic_vector) return std_ulogic_vector is
	begin
		return std_ulogic_vector(std_logic_vector(left) + std_logic_vector(right));	
	end function;

	function "+" (left : std_ulogic_vector; right : integer) return std_ulogic_vector is
	begin
		return std_ulogic_vector(std_logic_vector(left) + std_logic_vector(to_unsigned(right, left'length)));	
	end function;
end package body;