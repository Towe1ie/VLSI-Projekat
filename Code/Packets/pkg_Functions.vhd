library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package Functions is
-- **** Aritmeticko logicke operacije ****
	function "+" (left, right : std_ulogic_vector) return std_ulogic_vector;
	function "+" (left : std_ulogic_vector; right : integer) return std_ulogic_vector;
	function "+" (left : std_ulogic_vector; right : std_ulogic) return std_ulogic_vector;
	function "-" (left, right : std_ulogic_vector) return std_ulogic_vector;
	function "-" (left : std_ulogic_vector; right : integer) return std_ulogic_vector;
	function "-" (left : std_ulogic_vector; right : std_ulogic) return std_ulogic_vector;
	function "=" (left : std_ulogic_vector; right : integer) return boolean;
	function asr (v, cnt : std_ulogic_vector) return std_ulogic_vector;
	function lsr (v, cnt : std_ulogic_vector) return std_ulogic_vector;
	function lsl (v, cnt : std_ulogic_vector) return std_ulogic_vector;

-- **** Konverzija ****
	function to_integer(v : std_ulogic_vector) return integer;
end package;

package body Functions is
-- **** Aritmeticko logicke operacije ****
	function "+" (left, right : std_ulogic_vector) return std_ulogic_vector is
		variable ret : std_ulogic_vector(left'range);
	begin
		if is_X(left)
		then
			ret := left;
		elsif is_X(right)
		then
			ret := right;
		else
			ret := std_ulogic_vector(std_logic_vector(left) + std_logic_vector(right));
		end if;

		return ret;
	end function;

	function "+" (left : std_ulogic_vector; right : integer) return std_ulogic_vector is
	begin
		return left + std_ulogic_vector(to_unsigned(right, left'length));	
	end function;

	function "+" (left : std_ulogic_vector; right : std_ulogic) return std_ulogic_vector is
		variable tmp : std_ulogic_vector(left'range);
	begin
		tmp(0) := right;
		tmp(tmp'high downto 1) := (others => '0');
		return left + to_integer(tmp);
	end function;

	function "-" (left, right : std_ulogic_vector) return std_ulogic_vector is
		variable ret : std_ulogic_vector(left'range);
	begin
		if is_X(left)
		then
			ret := left;
		elsif is_X(right)
		then
			ret := right;
		else
			ret := std_ulogic_vector(std_logic_vector(left) - std_logic_vector(right));
		end if;

		return ret;
	end function;

	function "-" (left : std_ulogic_vector; right : integer) return std_ulogic_vector is
	begin
		return left - std_ulogic_vector(to_unsigned(right, left'length));	
	end function;

	function "-" (left : std_ulogic_vector; right : std_ulogic) return std_ulogic_vector is
		variable tmp : std_ulogic_vector(left'range);
	begin
		tmp(0) := right;
		tmp(tmp'high downto 1) := (others => '0');
		return left - to_integer(tmp);
	end function;

	function "=" (left : std_ulogic_vector; right : integer) return boolean is
	begin
		return left = std_ulogic_vector(to_unsigned(right, left'length));
	end;

	function asr (v, cnt : std_ulogic_vector) return std_ulogic_vector is
	begin
		return std_ulogic_vector(shift_right(signed(v), to_integer(cnt)));
	end function;

	function lsr (v, cnt : std_ulogic_vector) return std_ulogic_vector is
	begin
		return std_ulogic_vector(shift_right(unsigned(v), to_integer(cnt)));
	end function;

	function lsl (v, cnt : std_ulogic_vector) return std_ulogic_vector is
	begin
		return std_ulogic_vector(shift_left(unsigned(v), to_integer(cnt)));
	end function;

-- **** Konverzija ****
	function to_integer(v : std_ulogic_vector) return integer is
	begin
		if (is_X(v))
		then
			return 0;
		else
			return to_integer(unsigned(v));
		end if;
	end function;

end package body;