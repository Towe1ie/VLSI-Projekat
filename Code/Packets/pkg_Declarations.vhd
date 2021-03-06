library ieee;

use ieee.std_logic_1164.all;

package Declarations is
	constant OM_ADDR_SIZE : natural := 8;
	subtype OM_Addr is std_ulogic_vector(OM_ADDR_SIZE - 1 downto 0);

	constant WORD_SIZE : natural := 32;
	subtype Word is std_ulogic_vector(WORD_SIZE - 1 downto 0);

	constant GPR_ADDR_SIZE : natural := 5;
	subtype GPR_addr is std_ulogic_vector(GPR_ADDR_SIZE - 1 downto 0);

	type Mnemonic is (AND_I, SUB_I, ADD_I, ADC_I, SBC_I, CMP_I, SSUB_I, SADD_I, SADC_I, SSBC_I, MOV_I, NOT_I, SL_I, SR_I, ASR_I, MOV_IMM_I, SMOV_IMM_I, LOAD_I, STORE_I, BEQ_I, BGT_I, BHI_I, BAL_I, BLAL_I, STOP_I, ERROR_I);
	attribute enum_encoding : string;
	attribute enum_encoding of Mnemonic : type is "sequential";

	type Instr_type is (ALU_Type, BRANCH_Type, LOAD_STORE_Type, STOP_Type, ERROR_Type);

	constant IF_ID_BUFFER_ADDR_SIZE : natural := 3;

	constant N_POS : natural := 31;
	constant Z_POS : natural := 30;
	constant C_POS : natural := 29;
	constant V_POS : natural := 28;

	constant LINK_REG_DST : natural := 31;

	constant DATA_CACHE_DELAY : natural := 3;
	
	constant instr_cache_file_name : string := "testInstrukcije.txt";
	constant data_cache_file_name : string := "dataMemory.txt";

-- **** Other ****
	type Data_hazard_info is record
		dst : GPR_addr;
		valid : std_ulogic;
		value : Word;
		CSR : Word;
		updateCSR : std_ulogic;
		canForward : std_ulogic;
		elapsedTime : natural;
	end record;

-- **** Caches ****
	type Instr_Cache_data is record
		data1, data2 : Word;
		initPC : OM_Addr;
	end record;

	type Instr_Cahce_addr is record
		addr1, addr2 : OM_Addr;
	end record;

	type Data_Cache_in is record
		addr : OM_Addr;
		wr, rd : std_ulogic;
		data_in : Word;
	end record;

	type Data_Cache_out is record
		data_out : Word;
	end record;

-- **** IF/ID ****
	type Undecoded_Instruction is record
		pc : OM_Addr;
		raw_instr : Word;
	end record;

	type IF_ID_out is record
		put2 : std_ulogic;
		instr1, instr2 : Undecoded_Instruction;
	end record;

	type ID_IF_out is record
		free2 : std_ulogic;
	end record;

-- **** ID/GPR ****
	type ID_GPR_addr is record
		addr1, addr2, addr3, addr4 : GPR_addr;
	end record;

	type GPR_ID_data is record
		dataOut1, dataOut2, dataOut3, dataOut4 : Word;
	end record;

-- **** ID ****
	type Instruction_info is record
		src1_addr, src2_addr, dst_addr : GPR_addr;	
		imm : Word;
		pc : OM_Addr;
		jmp_offset : Word;
		op : Mnemonic;
		need_CSR : std_ulogic;
		updateCSR : std_ulogic;
	end record;

	type Decoded_Instruction is record
		info : Instruction_info;
		src1_Value, src2_Value : Word;
		CSR : Word;
		ready : std_ulogic;
	end record;

-- **** ID/EXE ****
	type EXE_Data_Hazard_Control is record
		alu1_info, alu2_info, load_store_info : Data_hazard_info;
	end record;

-- **** WB/ID ****
	type WB_Data_Hazard_Control is record
		alu1_info, alu2_info, loadStore_info : Data_hazard_info;
	end record;

	type WB_Reg_Instr is record
		op : Mnemonic;
		dst : GPR_addr;
		value : Word;
		CSR : Word;
		updateCSR : std_ulogic;
		cnd : std_ulogic;
		jmp_addr : OM_Addr;
		pc : OM_Addr;
		valid : std_ulogic;
	end record;

	--type EXE_WB_out is record
	--	instr_info : WB_Reg_Instr;
		--put : std_ulogic;
	--end record;

	type WB_GPR_out is record
		wrAlu1, wrAlu2, wrLoadStore, wrBr : std_ulogic;
		alu1_addr, alu2_addr, loadStore_addr, br_addr : GPR_addr;
		alu1_value, alu2_value, loadStore_value, br_value : Word;
	end record;

	type WB_CSR_out is record
		wrCSR : std_ulogic;
		CSR : Word;
	end record;
end package;