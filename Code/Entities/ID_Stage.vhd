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

		in_loadStoreBusy : in std_ulogic;
		in_branch_busy : in std_ulogic;

		first_instr, second_instr : out Decoded_Instruction;

		clk, reset, flush : std_ulogic
	);
end entity;

architecture ID_Stage_arch of ID_Stage is
-- **** FIFO logic ****
	type FIFO_Reg_file is array (0 to 2**IF_ID_BUFFER_ADDR_SIZE - 1) of Undecoded_Instruction;
	signal buff, buff_next : FIFO_Reg_file;

	signal tail, head, tailInc, headInc : std_ulogic_vector(IF_ID_BUFFER_ADDR_SIZE - 1 downto 0);
	signal put2, wr2, take1, take2, free2 : std_ulogic;

-- **** ****
	signal first, second : Undecoded_Instruction;
	signal firstDecoded, secondDecoded : Decoded_Instruction;
	signal firstReady, secondReady : std_ulogic;
	signal reset_or_flush : std_ulogic;
begin
	reset_or_flush <= reset or flush;
	tailInc <= tail + 1;
	headInc <= head + 1;

	first <= buff(to_integer_unsigned(head));
	second <= buff(to_integer_unsigned(headInc));

	decode(first, firstDecoded.info);
	decode(second, secondDecoded.info);

	out_GPR_addr.addr1 <= firstDecoded.info.src1_addr;
	out_GPR_addr.addr2 <= firstDecoded.info.src2_addr;
	out_GPR_addr.addr3 <= secondDecoded.info.src1_addr;
	out_GPR_addr.addr4 <= secondDecoded.info.src2_addr;

	firstDecoded.ready <= firstReady;
	first_instr <= firstDecoded;

	secondDecoded.ready <= secondReady;
	second_instr <= secondDecoded;

-- **** Data hazards logic ****
	process(in_GPR_data, firstDecoded, secondDecoded, in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, in_CSR, in_loadStoreBusy, in_branch_busy)
		variable hazard_src1, hazard_src2, hazard_CSR, forwarded_src1, forwarded_src2, forwarded_CSR : boolean;
		variable forwardValue : Word;
		variable firstRdy_tmp : std_ulogic;
		variable second_to_first_dependance, bothBranch, bothLoad, loadStoreBusy : boolean;
		variable firstInstr_type, secondInstr_type : Instr_type;
	begin
	-- First instruction
		-- postavljamo sve signale na podrazumevane vrednosti da ne bi doslo do lecovanja
		firstReady <= '1'; -- pretpostavljamo da ce biti ready instrukcija, pa ako shvatimo da nije ready promenicemo na 0
		firstRdy_tmp := '1'; -- privremena PROMENLJIVA za racunanje finalne vrednosti za ready, na kraju svih racunanja ce biti prosledjena u firstReady
							 -- mora promenljiva jer se promena signala vidi tek kad se zavrsi proces
		firstDecoded.src1_Value <= in_GPR_data.dataOut1; -- pretpostavljamo da nece biti hazarda pa prosledjujemo vrednosti iz registara.
		firstDecoded.src2_Value <= in_GPR_data.dataOut2; -- ako shvatimo suprotno, promenicemo signal koji upisujemo u value
		firstDecoded.CSR <= in_CSR;
		hazard_src1 := false; -- oznacava da li je doslo do hazarda
		hazard_src2 := false;
		hazard_CSR := false;
		forwarded_CSR := false; -- oznacava da li je uspeo da se prosledi podatak u slucaju da je bilo hazarda
		firstInstr_type := get_instr_type(firstDecoded.info.op);

		-- provera da li se desio hazard na operandima
		-- ako su immed ili branch ne moze se desiti data hazard na operandima
		-- immed inherentno ima operand u instrukciji, a branch nema operande (ne mesati sa CSR, na njemu se moze desiti hazard kod Brancha ali to se proverava kasnije)
		if (not isImmed(firstDecoded.info.op) and not (firstInstr_type = BRANCH_Type))
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
				firstRdy_tmp := '0';
			end if;
		end if;

		-- provera da li se desio hazard na CSR registru
		-- za instrukcije koje ne koriste CSR ostace podrazumevana vrednost za hazard_CSR = false
		if (firstDecoded.info.need_CSR = '1')
		then
			resolve_Data_Hazard_CSR(in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, hazard_CSR, forwardValue, forwarded_CSR);
			if (forwarded_CSR)
			then
				firstDecoded.CSR <= forwardValue;
			end if;
		end if;

		-- load ne moze da predje u EXE ako je zauzeta LoadStore funkcionalna jedinica
		-- branchovima ne dozvoljavamo da preskoce LoadStore instrukcije
		if ((firstInstr_type = LOAD_STORE_Type or firstInstr_type = BRANCH_Type) and in_loadStoreBusy = '1')
		then
			firstRdy_tmp := '0';
		end if;

		-- ne dozvoljavamo da store zapocne upis ako postoji instrukcija u Branch jedinici
		-- problem bi nastao ako bi se ispostavilo da je branch ispunjen 
		-- (a to ce se znati tek u sledecem taktu kada instrukcija izadje iz Branch jedinice) 
		-- sto implicira da store koji je posle njega ne treba da se izvrsi, a u tom trenutku bi vec poceo izvrsavanje
		if (firstDecoded.info.op = STORE_I and in_branch_busy = '1')
		then
			firstRdy_tmp := '0';
		end if;

		if ((hazard_CSR and not forwarded_CSR) or firstDecoded.info.op = ERROR_I)
		then
			firstRdy_tmp := '0';
		end if;

		-- upis finalne vrednosti u signal
		firstReady <= firstRdy_tmp;

	-- Second instruction
		-- slicno kao i za prvu instrukciju samo se jos dodatno mora proveriti da li druga instrukcija zavisi od prve
		secondReady <= '1';
		secondDecoded.src1_Value <= in_GPR_data.dataOut3;
		secondDecoded.src2_Value <= in_GPR_data.dataOut4;
		secondDecoded.CSR <= in_CSR;
		second_to_first_dependance := false;
		hazard_src1 := false;
		hazard_src2 := false;
		hazard_CSR := false;
		forwarded_CSR := false;
		secondInstr_type := get_instr_type(secondDecoded.info.op);

		if (not isImmed(secondDecoded.info.op) and not (secondInstr_type = BRANCH_Type))
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

			-- ukoliko druga instrukcija kao izvorisni koristi neki registar koji je prvoj destinacioni onda ce nastati hazard
			if (secondDecoded.info.src1_addr = firstDecoded.info.dst_addr or (secondDecoded.info.src2_addr = firstDecoded.info.dst_addr and not useOneOperand(firstDecoded.info.op)))
			then
				second_to_first_dependance := true;
			end if;

			if ((hazard_src1 and not forwarded_src1) or (hazard_src2 and not forwarded_src2 and not useOneOperand(firstDecoded.info.op)))
			then
				secondReady <= '0';
			end if;
		end if;

		if (secondDecoded.info.need_CSR = '1')
		then
			resolve_Data_Hazard_CSR(in_EXE_Data_Hazard_Control, in_WB_Data_Hazard_Control, hazard_CSR, forwardValue, forwarded_CSR);
			if (forwarded_CSR)
			then
				secondDecoded.CSR <= forwardValue;
			end if;

			-- dodatna provera da li i prva koristi CSR, jer i onda nastaje hazard
			if (firstDecoded.info.updateCSR = '1')
			then
				second_to_first_dependance := true;
			end if;
		end if;

		-- ako su obe instrukcije Branch ili LoadStore onda ih ne mozemo obe pustiti u EXE
		-- jer imamo samo po jednu funkcionalnu jedinicu za te operacije
		bothBranch :=secondInstr_type = BRANCH_Type and firstInstr_type = BRANCH_Type;
		bothLoad := secondInstr_type = LOAD_STORE_Type and firstInstr_type = LOAD_STORE_Type;

		if ((hazard_CSR and not forwarded_CSR) or second_to_first_dependance or secondDecoded.info.op = ERROR_I or bothBranch or bothLoad or firstRdy_tmp = '0')
		then
			secondReady <= '0';
		end if;

		if (secondInstr_type = BRANCH_Type and in_loadStoreBusy = '1')
		then
			secondReady <= '0';
		end if;

		if (secondDecoded.info.op = STORE_I and (in_branch_busy = '1' or firstInstr_type = BRANCH_Type))
		then
			secondReady <= '0';
		end if;

		if (secondDecoded.info.op = STOP_I)
		then
			secondReady <= '1';
		end if;
	end process;

-- **** Other ****
	-- signali za vadjenje instrukcija iz bafera
	take1 <= 	'1' when firstReady = '1' and secondReady = '0' else
				'0';
	take2 <=	'1' when firstReady = '1' and secondReady = '1' else
				'0';
	-- instanciranje kontrolera za bafer
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

	-- logika za bafer
	process(clk)
	begin
		if (rising_edge(clk))
		then
			if (reset_or_flush = '1')
			then
				for i in buff'range
				loop
					buff(i).raw_instr <= (others => 'U');
					buff(i).pc <= (others => 'U');
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
			buff_next(to_integer_unsigned(tail)) <= in_if_stage.instr1;
			buff_next(to_integer_unsigned(tailInc)) <= in_if_stage.instr2;
		end if;
	end process;
	put2 <= in_if_stage.put2;

	out_if_stage.free2 <= free2;
end architecture;