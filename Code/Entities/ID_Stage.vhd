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
	signal reset_or_flush : std_ulogic;
begin
	reset_or_flush <= reset or flush;
	tailInc <= tail + 1;
	headInc <= head + 1;
	take1 <= '0';
	take2 <= '0';

	first <= buff(to_integer(head));
	second <= buff(to_integer(headInc));

	out_GPR_addr.addr1 <= get_reg_addr(first, 1);
	out_GPR_addr.addr2 <= get_reg_addr(first, 2);
	out_GPR_addr.addr3 <= get_reg_addr(second, 1);
	out_GPR_addr.addr4 <= get_reg_addr(second, 2);

	decode(first, first_instr.info);
	decode(second, second_instr.info);

	first_instr.src1_Value <= in_GPR_data.dataOut1;
	first_instr.src2_Value <= in_GPR_data.dataOut2;
	first_instr.CSR <= in_CSR;
	second_instr.src1_Value <= in_GPR_data.dataOut3;
	second_instr.src2_Value <= in_GPR_data.dataOut4;
	second_instr.CSR <= in_CSR;


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