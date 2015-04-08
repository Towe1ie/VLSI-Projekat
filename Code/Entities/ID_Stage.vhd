library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;
use work.Components.all;
use work.Functions.all;
use work.DecodeFunctions.all;

entity ID_Stage is
	port
	(
		out_if_stage : out ID_IF_out;
		in_if_stage : in IF_ID_out;

		out_GPR_addr : out ID_GPR_addr;
		in_GPR_data : in GPR_ID_data;

		in_CSR : in Word;

		in_EXE_data_hazard_control : in EXE_Data_Hazard_Control;
		in_WB_data_hazard_control : in WB_Data_Hazard_Control;

		first_instr, second_instr : out Decoded_Instruction;

		clk, reset, flush : std_ulogic
	);
end entity;

architecture ID_Stage_arch of ID_Stage is
-- **** FIFO logic ****
	type FIFO_Reg_file is array (0 to 2**IF_ID_BUFFER_ADDR_SIZE - 1) of Word;
	signal buff, buff_next : FIFO_Reg_file;

	signal tail, head, tailInc, headInc : std_ulogic_vector(IF_ID_BUFFER_ADDR_SIZE - 1 downto 0);
	signal put2, wr2, take1, take2, free2 : std_ulogic;

-- **** ****
	signal first, second : Word;
	signal firstDecoded, secondDecoded : Decoded_Instruction;
	signal firstReady, secondReady : std_ulogic;
	signal reset_or_flush : std_ulogic;
begin
	reset_or_flush <= reset or flush;
	tailInc <= tail + 1;
	headInc <= head + 1;

	first <= buff(to_integer(head));
	second <= buff(to_integer(headInc));

	out_GPR_addr.addr1 <= get_reg_addr(first, 1);
	out_GPR_addr.addr2 <= get_reg_addr(first, 2);
	out_GPR_addr.addr3 <= get_reg_addr(second, 1);
	out_GPR_addr.addr4 <= get_reg_addr(second, 2);

	decode(first, firstDecoded.info);
	decode(second, secondDecoded.info);

	firstDecoded.CSR <= in_CSR;
	--firstReady <= '1';
	firstDecoded.ready <= firstReady;
	first_instr <= firstDecoded;

	
	secondDecoded.CSR <= in_CSR;
	--secondReady <= '1';
	secondDecoded.ready <= secondReady;
	second_instr <= secondDecoded;

-- **** Data hazards logic ****
	process(in_GPR_data, firstDecoded, secondDecoded, in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control)
		variable hazard_src1, hazard_src2, forwarded_src1, forwarded_src2 : boolean;
		variable forwardValue : Word;
		variable second_to_first_dependance : boolean;
	begin
	-- First instruction
		firstReady <= '1';
		firstDecoded.src1_Value <= in_GPR_data.dataOut1;
		firstDecoded.src2_Value <= in_GPR_data.dataOut2;

		if (not isImmed(firstDecoded.info.op))
		then
			resolve_Data_Hazard(firstDecoded.info.src1_addr, in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, hazard_src1, forwardValue, forwarded_src1);
			if (forwarded_src1)
			then
				firstDecoded.src1_Value <= forwardValue;
			end if;

			resolve_Data_Hazard(firstDecoded.info.src2_addr, in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, hazard_src2, forwardValue, forwarded_src2);
			if (forwarded_src2)
			then
				firstDecoded.src2_Value <= forwardValue;
			end if;

			if ((hazard_src1 and not forwarded_src1) or (hazard_src2 and not forwarded_src2 and not useOneOperand(firstDecoded.info.op)))
			then
				firstReady <= '0';
			end if;
		end if;

	-- Second instruction
		secondReady <= '1';
		secondDecoded.src1_Value <= in_GPR_data.dataOut3;
		secondDecoded.src2_Value <= in_GPR_data.dataOut4;
		second_to_first_dependance := false;

		if (not isImmed(secondDecoded.info.op))
		then
			resolve_Data_Hazard(secondDecoded.info.src1_addr, in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, hazard_src1, forwardValue, forwarded_src1);
			if (forwarded_src1)
			then
				secondDecoded.src1_Value <= forwardValue;
			end if;

			resolve_Data_Hazard(secondDecoded.info.src2_addr, in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, hazard_src2, forwardValue, forwarded_src2);
			if (forwarded_src2)
			then
				secondDecoded.src2_Value <= forwardValue;
			end if;

			if (secondDecoded.info.src1_addr = firstDecoded.info.dst_addr or (secondDecoded.info.src2_addr = firstDecoded.info.dst_addr and not useOneOperand(firstDecoded.info.op)))
			then
				second_to_first_dependance := true;
			end if;

			if ((hazard_src1 and not forwarded_src1) or (hazard_src2 and not forwarded_src2 and not useOneOperand(firstDecoded.info.op)) or second_to_first_dependance)
			then
				secondReady <= '0';
			end if;
		end if;
	end process;

-- **** Other ****
	take1 <= 	'1' when firstReady = '1' and secondReady = '0' else
				'0';
	take2 <=	'1' when firstReady = '1' and secondReady = '1' else
				'0';

	fifoControler : FIFO_Controler
		generic map (IF_ID_BUFFER_ADDR_SIZE)
		port map(
			tail => tail,
			head => head,
			full => open,
			empty => open,
			free2 => free2,
			have2 => open,
			wr1 => open,
			wr2 => wr2,
			put1 => '0',
			put2 => put2,
			take1 => take1,
			take2 => take2,
			reset => reset_or_flush,
			clk => clk 
			);

	process(clk)
	begin
		if (rising_edge(clk))
		then
			if (reset_or_flush = '1')
			then
				for i in buff'range
				loop
					buff(i) <= (others => 'U');
				end loop;
			else
				for i in buff'range
				loop
					buff(i) <= buff_next(i);
				end loop;
			end if;
		end if;
	end process;

	process(buff, wr2, in_if_stage, tail, tailInc)
	begin
		for i in buff'range
		loop
			buff_next(i) <= buff(i);
		end loop;

		if (wr2 = '1')
		then
			buff_next(to_integer(tail)) <= in_if_stage.instr1;
			buff_next(to_integer(tailInc)) <= in_if_stage.instr2;
		end if;
	end process;
	put2 <= in_if_stage.put2;

	out_if_stage.free2 <= free2;
end architecture;