library ieee;
use ieee.std_logic_1164.all;

entity DECOD7 is

	port
	(
		-- Input ports
		ABCD	: in  std_logic_vector(3 downto 0);


		-- Output ports
		DISPLAY	: out std_logic_vector(6 downto 0)
	);
end DECOD7;


architecture arch_DECOD7 of DECOD7 is


begin

		with ABCD select
			DISPLAY <= "0000001" when "0000",
							"1001111" when "0001",
							"0010010" when "0010",
							"0000110" when "0011",
							"1001100" when "0100",
							"0100100" when "0101",
							"0100000" when "0110",
							"0001111" when "0111",
							"0000000" when "1000",
							"0000100" when "1001",
							"1111111" when others;
	
end arch_DECOD7;

 