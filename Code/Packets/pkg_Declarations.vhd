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
-- **** Caches ****
	type Instr_Cache_data is record
		data1, data2 : Word;
		initPC : OM_Addr;
	end record;

	type Instr_Cahce_addr is record
		addr1, addr2 : OM_Addr;
	end record;

-- **** IF/ID ****
	constant IF_ID_BUFFER_ADDR_SIZE : natural := 3;
	type IF_ID_out is record
		put2 : std_ulogic;
		instr1, instr2 : Word;
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
		op : Mnemonic;
		need_CSR : std_ulogic;
	end record;

	type Decoded_Instruction is record
		info : Instruction_info;
		src1_Value, src2_Value : Word;
		CSR : Word;
	end record;
end package;