library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    generic (
        ADDR_WIDTH : integer := 8;
        DATA_WIDTH : integer := 8
    );
    port (
        clk      : in  STD_LOGIC;
        we       : in  STD_LOGIC;
        address  : in  STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end RAM;

architecture Behavioral of RAM is
    type ram_type is array (0 to 2**ADDR_WIDTH-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal memory : ram_type;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                memory(to_integer(unsigned(address))) <= data_in;
            end if;
            data_out <= memory(to_integer(unsigned(address)));
        end if;
    end process;
end Behavioral;