library ieee;
library work;

use work.Declarations.all;
use ieee.std_logic_1164.all;

package DecodeFunctions is
	procedure decode(w : Word; signal instr : out Instruction_info);
	function decode_oc(w : Word) return Mnemonic;
	function ext_imm(w : Word) return Word;
	function check_need_CSR(m : Mnemonic) return std_ulogic;
	function get_reg_addr(w : Word; flag : natural) return GPR_addr; -- flag: 0-dst, 1-src1, 2-src2,
end package;

package body DecodeFunctions is
	procedure decode(w : Word; signal instr : out Instruction_info) is
		variable op : Mnemonic;
	begin
		op := decode_oc(w);
		instr.op <= op;
		instr.src1_addr <= get_reg_addr(w, 1);
		instr.src2_addr <= get_reg_addr(w, 2);
		instr.dst_addr <= get_reg_addr(w, 0);
		instr.imm <= ext_imm(w);
		instr.need_CSR <= check_need_CSR(op);
	end procedure;

	function ext_imm(w : Word) return Word is
		variable ret : Word;
	begin
		ret(31 downto 17) := (others => w(16));
		ret(16 downto 0) := w(16 downto 0);
		return ret;
	end function;

	function check_need_CSR(m : Mnemonic) return std_ulogic is
	begin
		if (m = ADC_I or m = SBC_I or m = SADC_I or m = SSBC_I or m = BEQ_I or m = BGT_I or m = BHI_I or m = BAL_I or m = BLAL_I)
		then
			return '1';
		else
			return '0';
		end if;
	end function;

	function get_reg_addr(w : Word; flag : natural) return GPR_addr is
		variable ret : GPR_addr;
	begin
		if (flag = 0)
		then
			ret := w(21 downto 17);
		elsif (flag = 1)
		then
			ret := w(26 downto 22);
		elsif (flag = 2)
		then
			ret := w(16 downto 12);
		else
			ret := (others => 'X');
		end if;

		return ret;
	end function;

	function decode_oc(w : Word) return Mnemonic is
		variable ret : Mnemonic;
		variable oc : std_ulogic_vector(4 downto 0);
	begin
		oc := w(31 downto 27);
		case oc is
			when "00000" => ret := AND_I;
			when "00001" => ret := SUB_I;
			when "00010" => ret := ADD_I;
			when "00011" => ret := ADC_I;
			when "00100" => ret := SBC_I;
			when "00101" => ret := CMP_I;
			when "00110" => ret := SSUB_I;
			when "00111" => ret := SADD_I;
			when "01000" => ret := SADC_I;
			when "01001" => ret := SSBC_I;
			when "01010" => ret := MOV_I;
			when "01011" => ret := NOT_I;
			when "01100" => ret := SL_I;
			when "01101" => ret := SR_I;
			when "01110" => ret := ASR_I;
			when "01111" => ret := MOV_IMM_I;
			when "10000" => ret := SMOV_IMM_I;

			when "10100" => ret := LOAD_I;
			when "10101" => ret := STORE_I;

			when "11000" => ret := BEQ_I;
			when "11001" => ret := BGT_I;
			when "11010" => ret := BHI_I;
			when "11011" => ret := BAL_I;
			when "11100" => ret := BLAL_I;

			when "11111" => ret := STOP_I;

			when others => ret := ERROR_I;
		end case;

		return ret;
	end function;
end package body;