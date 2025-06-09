library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GenericTimer is
    generic (
        MAX_COUNT : integer := 10  -- Duración máxima del temporizador (en segundos)
    );
    port (
        clk_1Hz : in std_logic;  -- Reloj de 1 Hz
        reset   : in std_logic;  -- Reiniciar temporizador
        start   : in std_logic;  -- Iniciar temporizador
        done    : out std_logic  -- Señal de fin de temporización (1 solo ciclo)
    );
end entity GenericTimer;

architecture Behavioral of GenericTimer is
    signal counter     : unsigned(5 downto 0) := (others => '0');
    signal counting    : std_logic := '0';
    signal done_reg    : std_logic := '0';
begin
    process(clk_1Hz, reset)
    begin
        if reset = '1' then
            counter   <= (others => '0');
            counting  <= '0';
            done_reg  <= '0';
        elsif rising_edge(clk_1Hz) then
            done_reg <= '0'; -- Valor por defecto cada ciclo

            if start = '1' and counting = '0' then
                -- Iniciar conteo
                counting <= '1';
                counter  <= (others => '0');
            elsif counting = '1' then
                if counter = to_unsigned(MAX_COUNT - 1, counter'length) then
                    -- Temporización completada
                    done_reg <= '1';
                    counting <= '0';
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    done <= done_reg;

end Behavioral;