library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Usamos NUMERIC_STD para operaciones aritméticas

entity Des2 is
    generic (
        INPUT_WIDTH : integer := 4 -- Ancho de la entrada (por defecto 4 bits)
    );
    port (
        entrada   : in  STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0); -- Entrada binaria
        unidades  : out STD_LOGIC_VECTOR (3 downto 0);              -- Unidades en BCD
        decenas   : out STD_LOGIC_VECTOR (3 downto 0)               -- Decenas en BCD
    );
end Des2;

architecture Behavioral of Des2 is
    signal num_entero : integer range 0 to 2**INPUT_WIDTH-1; -- Entero para la conversión
begin
    process(entrada)
    begin
        -- Convertir la entrada binaria a un entero
        num_entero <= to_integer(unsigned(entrada));

        -- Calcular decenas y unidades usando división y módulo
        decenas  <= std_logic_vector(to_unsigned(num_entero / 10, 4)); -- Decenas = entrada / 10
        unidades <= std_logic_vector(to_unsigned(num_entero mod 10, 4)); -- Unidades = entrada mod 10
    end process;
end Behavioral;