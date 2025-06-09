library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divisor is
    generic (
        DIVISOR : integer := 50_000_000  -- Valor por defecto para dividir un reloj de 50 MHz a 1 Hz
    );
    port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        enable  : in  STD_LOGIC := '1';       -- Permite habilitar o pausar el divisor
        clk_out : out STD_LOGIC
    );
end divisor;

architecture Behavioral of divisor is
    signal contador : integer range 0 to DIVISOR - 1 := 0;
    signal clk_aux  : STD_LOGIC := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            contador <= 0;
            clk_aux  <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                if contador = DIVISOR - 1 then
                    contador <= 0;
                    clk_aux  <= not clk_aux;  -- Toggle the output clock
                else
                    contador <= contador + 1;
                end if;
            end if;
        end if;
    end process;

    clk_out <= clk_aux;
end Behavioral;
