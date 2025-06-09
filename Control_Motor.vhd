library IEEE;
-- Importa la librería IEEE que contiene definiciones estándar de VHDL
use IEEE.STD_LOGIC_1164.ALL;
-- Importa definiciones de tipos y operaciones para lógica digital (std_logic)
use IEEE.NUMERIC_STD.ALL;
-- Importa definiciones para manipular números con signo y sin signo (numeric_std)
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Importa definiciones para operaciones aritméticas sobre STD_LOGIC_VECTOR (necesario para '+')

entity Control_Motor is
    Port (
        -- Entradas generales
        clk_50MHz    : in  STD_LOGIC;  -- Señal de reloj de 50 MHz para sincronización
        reset        : in  STD_LOGIC;  -- Señal de reinicio asíncrono (activo alto)
        -- Entradas de control para la puerta
        abrir_puerta : in  STD_LOGIC;  -- Señal para iniciar apertura de la puerta
        cerrar_puerta: in  STD_LOGIC;  -- Señal para iniciar cierre de la puerta
        -- Entradas de control para la elevación
        subir        : in  STD_LOGIC;  -- Señal para activar movimiento de subida
        bajar        : in  STD_LOGIC;  -- Señal para activar movimiento de bajada
        -- Salidas para el motor de la puerta
        puerta_A     : out STD_LOGIC;  -- Control de fase A del motor de puerta
        puerta_B     : out STD_LOGIC;  -- Control de fase B del motor de puerta
        -- Salidas para el sistema de elevación
        elevacion_A  : out STD_LOGIC;  -- Control de fase A del motor de elevación
        elevacion_B  : out STD_LOGIC   -- Control de fase B del motor de elevación
    );
end Control_Motor;

architecture Behavioral of Control_Motor is
    -- Declaración de señales internas para sincronizar y dividir reloj
    signal clk_div         : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');  -- Contador para dividir frecuencia
    signal clk_puerta      : STD_LOGIC := '0';  -- Reloj dividido para controlar velocidad de la puerta
    signal clk_elevacion   : STD_LOGIC := '0';  -- Reloj dividido para controlar velocidad de elevación
begin

    -- Proceso de división de reloj principal
    process(clk_50MHz, reset)
    begin
        if reset = '1' then
            -- Si se activa reset, reinicia contador y salidas de reloj
            clk_div       <= (others => '0');
            clk_puerta    <= '0';
            clk_elevacion <= '0';
        elsif rising_edge(clk_50MHz) then
            -- En cada flanco de subida del reloj de 50 MHz
            clk_div <= clk_div + 1;  -- Incrementa contador de división

            -- Asigna bits del contador para generar diferentes frecuencias
            clk_puerta    <= clk_div(24);  -- Usa bit 24 para reloj de puerta (~3 Hz)
            clk_elevacion <= clk_div(22);  -- Usa bit 22 para reloj de elevación (~12 Hz)
        end if;
    end process;

    -- Proceso de control del motor de la puerta basado en señales de control
    process(clk_puerta, reset)
    begin
        if reset = '1' then
            -- Si se activa reset, detiene el motor de la puerta
            puerta_A <= '0';
            puerta_B <= '0';
        elsif rising_edge(clk_puerta) then
            -- En cada pulso de reloj de puerta, evalúa comandos
            if abrir_puerta = '1' and cerrar_puerta = '0' then
                -- Si se pide abrir la puerta
                puerta_A <= '1';  -- Activa fase A
                puerta_B <= '0';  -- Desactiva fase B
            elsif cerrar_puerta = '1' and abrir_puerta = '0' then
                -- Si se pide cerrar la puerta
                puerta_A <= '0';  -- Desactiva fase A
                puerta_B <= '1';  -- Activa fase B
            else
                -- Si no hay comando o hay comandos contradictorios
                puerta_A <= '0';  -- Detiene ambas fases
                puerta_B <= '0';
            end if;
        end if;
    end process;

    -- Proceso de control del sistema de elevación basado en señales de control
    process(clk_elevacion, reset)
    begin
        if reset = '1' then
            -- Si se activa reset, detiene el motor de elevación
            elevacion_A <= '0';
            elevacion_B <= '0';
        elsif rising_edge(clk_elevacion) then
            -- En cada pulso de reloj de elevación, evalúa comandos
            if subir = '1' and bajar = '0' then
                -- Si se pide subir
                elevacion_A <= '1';  -- Activa fase A de elevación
                elevacion_B <= '0';  -- Desactiva fase B
            elsif bajar = '1' and subir = '0' then
                -- Si se pide bajar
                elevacion_A <= '0';  -- Desactiva fase A
                elevacion_B <= '1';  -- Activa fase B de elevación
            else
                -- Si no hay comando o hay comandos contradictorios
                elevacion_A <= '0';  -- Detiene ambas fases
                elevacion_B <= '0';
            end if;
        end if;
    end process;

end Behavioral;
 -- Fin de la arquitectura Behavioral para Control_Motor



