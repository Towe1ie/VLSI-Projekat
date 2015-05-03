library ieee;
library work;

use work.Declarations.all;
use ieee.std_logic_1164.all;

package DecodeFunctions is
	procedure decode(w : Undecoded_Instruction; signal instr : out Instruction_info);
	function decode_oc(w : Word) return Mnemonic;
	function ext_imm(w : Word) return Word;
	function ext_jmpOffset(w : Word) return Word;
	function check_need_CSR(m : Mnemonic) return std_ulogic;
	function get_reg_addr(w : Word; flag : natural) return GPR_addr; -- flag: 0-dst, 1-src1, 2-src2,

	function get_instr_type(m : Mnemonic) return Instr_type;
	function isImmed(m : Mnemonic) return boolean;
	function useOneOperand(m : Mnemonic) return boolean;

	procedure resolve_Data_Hazard(src : GPR_addr; 
								exe_info : EXE_Data_Hazard_Control; 
								wb_info : WB_Data_Hazard_Control;
								hazard : out boolean;
								forw_value : out Word;
								forwarded : out boolean);

	procedure resolve_Data_Hazard_CSR(exe_info : EXE_Data_Hazard_Control; 
									wb_info : WB_Data_Hazard_Control;
									hazard : out boolean;
									forw_value : out Word;
									forwarded : out boolean);

end package;

package body DecodeFunctions is
	procedure decode(w : Undecoded_Instruction; signal instr : out Instruction_info) is
		variable op : Mnemonic;
	begin
		op := decode_oc(w.raw_instr);
		instr.op <= op;
		instr.src1_addr <= get_reg_addr(w.raw_instr, 1);
		if (op = STORE_I)
		then
			-- **** (Tekst projekta) Kod store instrukcije podatak iz R3 se smesta u memoriju 
			instr.src2_addr <= get_reg_addr(w.raw_instr, 0);
		else
			instr.src2_addr <= get_reg_addr(w.raw_instr, 2);
		end if;
		instr.dst_addr <= get_reg_addr(w.raw_instr, 0);
		instr.imm <= ext_imm(w.raw_instr);
		instr.jmp_offset <= ext_jmpOffset(w.raw_instr);
		instr.pc <= w.pc;
		instr.need_CSR <= check_need_CSR(op);
		instr.updateCSR <= '0';
		if (get_instr_type(op) = ALU_Type)
		then
			instr.updateCSR <= '1';
		end if;

	end procedure;

	function ext_imm(w : Word) return Word is
		variable ret : Word;
	begin
		ret(31 downto 17) := (others => w(16));
		ret(16 downto 0) := w(16 downto 0);

		return ret;
	end function;

	function ext_jmpOffset(w : Word) return Word is
		variable ret : Word;
	begin
		ret(31 downto 27) := (others => w(26));
		ret(26 downto 0) := w(26 downto 0);

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

	function get_instr_type(m : Mnemonic) return Instr_type is
	begin
		if (m = AND_I or m = SUB_I or m = ADD_I or m = ADC_I or
			m = SBC_I or m = CMP_I or m = SSUB_I or m = SADD_I or
			m = SADC_I or m = SSBC_I or m = MOV_I or m = NOT_I or m = SL_I or
			m = SR_I or m = ASR_I or m = MOV_IMM_I or m = SMOV_IMM_I)
		then
			return ALU_Type;
		elsif (m = LOAD_I or m = STORE_I)
		then
			return LOAD_STORE_Type;
		elsif (m = BEQ_I or m = BGT_I or m = BHI_I or m = BAL_I or m = BLAL_I)
		then
			return BRANCH_Type;
		elsif (m = STORE_I)
		then
			return STOP_Type;
		else
			return ERROR_Type;
		end if;
	end function;

	function isImmed(m : Mnemonic) return boolean is
	begin
		if (m = MOV_IMM_I or m = SMOV_IMM_I)
		then
			return true;
		else
			return false;
		end if;
	end function;

	function useOneOperand(m : Mnemonic) return boolean is
	begin
		if (m = MOV_I or m = NOT_I or m = LOAD_I)
		then
			return true;
		else
			return false;
		end if;
	end function;

-- **** Data hazard procedures ****
	procedure resolve_Data_Hazard(src : GPR_addr;
								exe_info : EXE_Data_Hazard_Control; 
								wb_info : WB_Data_Hazard_Control;
								hazard : out boolean;
								forw_value : out Word;
								forwarded : out boolean) is
	begin
		forw_value := (others => '0');
		forwarded := false;
		hazard := false;
		
		if (src = wb_info.loadStore_info.dst and wb_info.loadStore_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (wb_info.loadStore_info.canForward = '1')
			then
				forwarded := true;
				forw_value := wb_info.loadStore_info.value;
			end if;
		end if;

		if (src = wb_info.alu1_info.dst and wb_info.alu1_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (wb_info.alu1_info.canForward = '1')
			then
				forwarded := true;
				forw_value := wb_info.alu1_info.value;
			end if;
		end if;

		if (src = wb_info.alu2_info.dst and wb_info.alu2_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (wb_info.alu2_info.canForward = '1')
			then
				forwarded := true;
				forw_value := wb_info.alu2_info.value;
			end if;
		end if;

		-- **** Ako je instrukcija u LS jedinici samo jedan takt proverava se redosled ALU 1, LS, ALU 2
		-- **** U suprotnom LS, ALU 1, ALU 2
		if (src = exe_info.load_store_info.dst and exe_info.load_store_info.valid = '1' and exe_info.load_store_info.elapsedTime > 0)
		then
			hazard := true;
			forwarded := false;
			if (exe_info.load_store_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.load_store_info.value;
			end if;
		end if;

		if (src = exe_info.alu1_info.dst and exe_info.alu1_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (exe_info.alu1_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.alu1_info.value;
			end if;
		end if;

		if (src = exe_info.load_store_info.dst and exe_info.load_store_info.valid = '1' and exe_info.load_store_info.elapsedTime = 0)
		then
			hazard := true;
			forwarded := false;
			if (exe_info.load_store_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.load_store_info.value;
			end if;
		end if;

		if (src = exe_info.alu2_info.dst and exe_info.alu2_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (exe_info.alu2_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.alu2_info.value;
			end if;
		end if;
	end procedure;

	procedure resolve_Data_Hazard_CSR(exe_info : EXE_Data_Hazard_Control; 
									wb_info : WB_Data_Hazard_Control;
									hazard : out boolean;
									forw_value : out Word;
									forwarded : out boolean) is
	begin
		forw_value := (others => '0');
		forwarded := false;
		hazard := false;
		
		if (wb_info.loadStore_info.updateCSR = '1' and wb_info.loadStore_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (wb_info.loadStore_info.canForward = '1')
			then
				forwarded := true;
				forw_value := wb_info.loadStore_info.CSR;
			end if;
		end if;

		if (wb_info.alu1_info.updateCSR = '1' and wb_info.alu1_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (wb_info.alu1_info.canForward = '1')
			then
				forwarded := true;
				forw_value := wb_info.alu1_info.CSR;
			end if;
		end if;

		if (wb_info.alu2_info.updateCSR = '1' and wb_info.alu2_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (wb_info.alu2_info.canForward = '1')
			then
				forwarded := true;
				forw_value := wb_info.alu2_info.CSR;
			end if;
		end if;

		-- srediti redosled kada se bude radila LoadStore jedinica
		if (exe_info.alu1_info.updateCSR = '1' and exe_info.alu1_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (exe_info.alu1_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.alu1_info.CSR;
			end if;
		end if;

		if (exe_info.load_store_info.updateCSR = '1' and exe_info.load_store_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (exe_info.load_store_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.load_store_info.CSR;
			end if;
		end if;

		if (exe_info.alu2_info.updateCSR = '1' and exe_info.alu2_info.valid = '1')
		then
			hazard := true;
			forwarded := false;
			if (exe_info.alu2_info.canForward = '1')
			then
				forwarded := true;
				forw_value := exe_info.alu2_info.CSR;
			end if;
		end if;
	end procedure;
end package body;