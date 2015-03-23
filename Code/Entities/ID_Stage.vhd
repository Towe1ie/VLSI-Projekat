library ieee;
library work;

use ieee.std_logic_1164.all;
use work.Declarations.all;
use work.Components.all;
use work.Functions.all;

entity ID_Stage is
	port
	(
		out_if_stage : out ID_IF_out;
		in_if_stage : in IF_ID_out;

		first, second : out Word;

		clk, reset, flush : std_ulogic
	);
end entity;

architecture ID_Stage_arch of ID_Stage is
	type FIFO_Reg_file is array (0 to 2**IF_ID_BUFFER_ADDR_SIZE - 1) of Word;
	signal buff, buff_next : FIFO_Reg_file;

	signal tail, head, tailInc, headInc : std_ulogic_vector(IF_ID_BUFFER_ADDR_SIZE - 1 downto 0);
	signal put2, wr2, take1, take2, free2 : std_ulogic;
	signal reset_or_flush : std_ulogic;
begin
	reset_or_flush <= reset or flush;
	tailInc <= tail + 1;
	headInc <= head + 1;
	take1 <= '0';
	take2 <= '0';

	first <= buff(to_integer(head));
	second <= buff(to_integer(headInc));

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