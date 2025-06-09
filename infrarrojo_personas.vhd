-- Bibliotecas estándar para lógica y operaciones numéricas
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entidad principal del sistema de detección de personas con sensores infrarrojos
entity infrarrojo_personas is
    Port (
        clk          : in  STD_LOGIC;      -- Señal de reloj del sistema (1 Hz)
        reset        : in  STD_LOGIC;      -- Reset síncrono activo en alto (1)
        sensor_ext   : in  STD_LOGIC;      -- Sensor exterior (entrada al local)
        sensor_int   : in  STD_LOGIC;      -- Sensor interior (salida del local)
        person_in    : out STD_LOGIC;      -- Pulso de 1 ciclo cuando se detecta entrada
        person_out   : out STD_LOGIC       -- Pulso de 1 ciclo cuando se detecta salida
    );
end infrarrojo_personas;

-- Implementación de la arquitectura comportamental
architecture Behavioral of infrarrojo_personas is
    -- Definición de estados para la máquina de estados finitos (FSM)
    type state_type is (
        IDLE,             -- Estado inicial: esperando activación de sensores
        EXT_TRIGGERED,    -- Sensor externo activado primero (posible entrada)
        INT_TRIGGERED,    -- Sensor interno activado primero (posible salida)
        CONFIRM_IN,       -- Confirmación de entrada: secuencia ext->int completada
        CONFIRM_OUT,      -- Confirmación de salida: secuencia int->ext completada
        DEBOUNCE          -- Período de espera para evitar falsas detecciones
    );
    
    -- Señales de estado actual y próximo estado
    signal current_state, next_state : state_type;
    
    -- Contador para temporización del período debounce (16 bits)
    signal debounce_counter : unsigned(15 downto 0) := (others => '0');
    
    -- Tiempo de debounce constante (2 segundos @ reloj de 1 Hz)
    constant DEBOUNCE_TIME : unsigned(15 downto 0) := to_unsigned(2, 16);
    
begin

    -- Proceso de registro de estado (sincronización con reloj)
    state_reg: process(clk, reset)
    begin
        if reset = '1' then
            -- Reset asíncrono: volver al estado inicial
            current_state <= IDLE;
        elsif rising_edge(clk) then
            -- Actualización del estado en cada flanco ascendente del reloj
            current_state <= next_state;
        end if;
    end process;

    -- Proceso de transición de estados (lógica combinacional)
    state_transition: process(current_state, sensor_ext, sensor_int, debounce_counter)
    begin
        -- Valores por defecto de las salidas (evita inferencia de latches)
        person_in <= '0';
        person_out <= '0';
        next_state <= current_state;  -- Mantener estado actual por defecto

        -- Máquina de estados finitos (FSM)
        case current_state is
            when IDLE =>
                -- Estado de espera: monitoreo de sensores
                if sensor_ext = '1' and sensor_int = '0' then
                    -- Activación única de sensor externo -> posible entrada
                    next_state <= EXT_TRIGGERED;
                elsif sensor_int = '1' and sensor_ext = '0' then
                    -- Activación única de sensor interno -> posible salida
                    next_state <= INT_TRIGGERED;
                end if;

            when EXT_TRIGGERED =>
                -- Espera confirmación de sensor interno para entrada
                if sensor_int = '1' then
                    -- Secuencia completa: ext->int = entrada confirmada
                    next_state <= CONFIRM_IN;
                elsif sensor_ext = '0' then
                    -- El sensor externo se desactiva sin confirmación -> cancelar
                    next_state <= IDLE;
                end if;

            when INT_TRIGGERED =>
                -- Espera confirmación de sensor externo para salida
                if sensor_ext = '1' then
                    -- Secuencia completa: int->ext = salida confirmada
                    next_state <= CONFIRM_OUT;
                elsif sensor_int = '0' then
                    -- El sensor interno se desactiva sin confirmación -> cancelar
                    next_state <= IDLE;
                end if;

            when CONFIRM_IN =>
                -- Generación de pulso de entrada (1 ciclo de reloj)
                person_in <= '1';
                -- Transición a estado de debounce
                next_state <= DEBOUNCE;

            when CONFIRM_OUT =>
                -- Generación de pulso de salida (1 ciclo de reloj)
                person_out <= '1';
                -- Transición a estado de debounce
                next_state <= DEBOUNCE;

            when DEBOUNCE =>
                -- Espera hasta completar el tiempo de debounce
                if debounce_counter = DEBOUNCE_TIME then
                    -- Finalizado el debounce -> volver a IDLE
                    next_state <= IDLE;
                end if;

            when others =>
                -- Manejo de estados no definidos (vuelta segura a IDLE)
                next_state <= IDLE;
        end case;
    end process;

    -- Proceso de contador para temporización del debounce
    debounce_proc: process(clk)
    begin
        if rising_edge(clk) then
            if current_state = DEBOUNCE then
                -- Incrementar contador mientras estamos en estado DEBOUNCE
                debounce_counter <= debounce_counter + 1;
            else
                -- Resetear contador en cualquier otro estado
                debounce_counter <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
