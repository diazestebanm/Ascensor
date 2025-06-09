-- Archivo: Alarmas.vhd
-- Descripción: Módulo de control de alarmas y notificaciones del sistema de ascensor.
--              Gestiona las señales acústicas (buzzer) y visuales (LEDs) para diferentes eventos.

-- Bibliotecas estándar
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.componentes.all;  -- Componentes personalizados del proyecto

-- Entidad principal del módulo de alarmas
entity Alarmas is
    port(
        -- Entradas de reloj y control
        clk_50mhz     : in  std_logic;  -- Reloj principal de 50MHz
        reset         : in  std_logic;  -- Reset global activo alto
        
        -- Entradas de eventos (provenientes del sistema principal)
        abrir_puerta  : in  std_logic;  -- Pulso indicando apertura forzada de puertas
        cerrar_puerta : in  std_logic;  -- Pulso indicando cierre forzado de puertas
        fallo_energia : in  std_logic;  -- Señal persistente de fallo de energía
        notificacion  : in  std_logic;  -- Señal persistente de notificación (botón emergencia)
        sobrecarga    : in  std_logic;  -- Señal persistente de sobrecarga
        
        -- Salidas de control
        buzzer        : out std_logic;  -- Salida al zumbador (mezcla de frecuencias)
        led_puerta_abi: out std_logic;  -- LED indicador puerta abierta
        led_puerta_cie: out std_logic;  -- LED indicador puerta cerrada
        led_fallo_en  : out std_logic;  -- LED fallo de energía
        led_notif     : out std_logic;  -- LED notificación activa
        led_sobrecarga: out std_logic   -- LED sobrecarga
    );
end Alarmas;

-- Arquitectura del módulo de alarmas
architecture Behavioral of Alarmas is
    -- Señales de reloj derivadas
    signal clk_1khz, clk_2khz : std_logic;  -- Relojes para tonos del buzzer (1kHz y 2kHz)
    
    -- Control del buzzer
    signal buzz_1khz, buzz_2khz : std_logic := '0';  -- Habilitación de tonos
    
    -- Definición de estados de la máquina de estados
    type state_type is (
        IDLE,                   -- Estado inactivo
        APERTURA_PUERTA,        -- Alarma apertura puerta (duración: 500ms)
        CIERRE_PUERTA,          -- Alarma cierre puerta (duración: 500ms)
        ALARMA_SOBRECARGA,      -- Alarma persistente por sobrecarga
        ALARMA_NOTIFICACION,    -- Alarma persistente por notificación
        ALARMA_FALLO_ENERGIA    -- Alarma persistente por fallo de energía
    );
    signal state : state_type := IDLE;  -- Estado actual
    
    -- Contadores para temporización
    signal contador_500ms : integer range 0 to 24999999 := 0; -- Contador para 500ms (50MHz*0.5)
    signal contador_200ms : integer range 0 to 9999999 := 0;  -- Contador para 200ms (50MHz*0.2)
    
    -- Registros para sincronización de entradas (anti-rebote)
    signal abrir_reg, cerrar_reg : std_logic := '0';  -- Registros para pulsos
    signal fallo_reg, notif_reg, sobrecarga_reg : std_logic := '0';  -- Registros para señales persistentes

begin
    ------------------------------------------------------------------------
    -- GENERACIÓN DE RELOJES DERIVADOS
    ------------------------------------------------------------------------
    
    -- Divisor de frecuencia para 1kHz (para tono bajo del buzzer)
    div_1khz: divisor
        generic map(DIVISOR => 50000)  -- 50MHz/50,000 = 1kHz
        port map(
            clk     => clk_50mhz, 
            reset   => reset, 
            enable  => '1', 
            clk_out => clk_1khz
        );
    
    -- Divisor de frecuencia para 2kHz (para tono alto del buzzer)
    div_2khz: divisor
        generic map(DIVISOR => 25000)  -- 50MHz/25,000 = 2kHz
        port map(
            clk     => clk_50mhz, 
            reset   => reset, 
            enable  => '1', 
            clk_out => clk_2khz
        );

    ------------------------------------------------------------------------
    -- SINCRONIZACIÓN DE ENTRADAS (ANTI-REBOTE)
    ------------------------------------------------------------------------
    
    -- Proceso de registro de entradas (sincronización con reloj de 50MHz)
    process(clk_50mhz)
    begin
        if rising_edge(clk_50mhz) then
            -- Registro de pulsos (anti-rebote)
            abrir_reg <= abrir_puerta;    -- Pulso apertura puerta
            cerrar_reg <= cerrar_puerta;  -- Pulso cierre puerta
            
            -- Registro de señales persistentes
            fallo_reg <= fallo_energia;    -- Estado fallo energía
            notif_reg <= notificacion;     -- Estado notificación
            sobrecarga_reg <= sobrecarga;  -- Estado sobrecarga
        end if;
    end process;

    ------------------------------------------------------------------------
    -- MÁQUINA DE ESTADOS PRINCIPAL
    ------------------------------------------------------------------------
    
    -- Proceso de la máquina de estados (control de alarmas)
    process(clk_50mhz, reset)
    begin
        if reset = '1' then  -- Reset asíncrono
            state <= IDLE;  -- Volver al estado inicial
            contador_500ms <= 0;  -- Reiniciar contador de 500ms
            contador_200ms <= 0;  -- Reiniciar contador de 200ms
            
        elsif rising_edge(clk_50mhz) then  -- Flanco ascendente del reloj
            -- Contadores siempre activos (para temporización)
            contador_500ms <= (contador_500ms + 1) mod 25000000;  -- Contador para 500ms
            contador_200ms <= (contador_200ms + 1) mod 10000000;  -- Contador para 200ms
            
            -- Lógica de transición de estados (prioridad definida)
            case state is
                when IDLE =>  -- Estado inactivo
                    -- Prioridad de mayor a menor (fallo energía > notificación > sobrecarga > cierre > apertura)
                    if fallo_reg = '1' then
                        state <= ALARMA_FALLO_ENERGIA;  -- Mayor prioridad
                    elsif notif_reg = '1' then
                        state <= ALARMA_NOTIFICACION;
                    elsif sobrecarga_reg = '1' then
                        state <= ALARMA_SOBRECARGA;
                    elsif cerrar_reg = '1' then
                        state <= CIERRE_PUERTA;
                        contador_500ms <= 0;  -- Reiniciar contador para temporización exacta
                    elsif abrir_reg = '1' then
                        state <= APERTURA_PUERTA;
                        contador_500ms <= 0;  -- Reiniciar contador para temporización exacta
                    end if;
                    
                when APERTURA_PUERTA =>  -- Alarma apertura puerta
                    if contador_500ms = 24999999 then  -- Esperar exactamente 500ms
                        state <= IDLE;  -- Volver a inactivo
                    end if;
                    
                when CIERRE_PUERTA =>  -- Alarma cierre puerta
                    if contador_500ms = 24999999 then  -- Esperar exactamente 500ms
                        state <= IDLE;  -- Volver a inactivo
                    end if;
                    
                when ALARMA_SOBRECARGA =>  -- Alarma por sobrecarga
                    if sobrecarga_reg = '0' then  -- Esperar a que se desactive la condición
                        state <= IDLE;
                    end if;
                    
                when ALARMA_NOTIFICACION =>  -- Alarma por notificación
                    if notif_reg = '0' then  -- Esperar a que se desactive la condición
                        state <= IDLE;
                    end if;
                    
                when ALARMA_FALLO_ENERGIA =>  -- Alarma por fallo de energía
                    if fallo_reg = '0' then  -- Esperar a que se desactive la condición
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- LÓGICA DE SALIDA (CONTROL DE LEDs Y BUZZER)
    ------------------------------------------------------------------------
    
    -- Proceso combinacional para control de salidas
    process(state, contador_200ms, contador_500ms)
    begin
        -- Valores por defecto (todas las salidas desactivadas)
        led_puerta_abi <= '0';  -- LED puerta abierta
        led_puerta_cie <= '0';  -- LED puerta cerrada
        led_fallo_en   <= '0';  -- LED fallo energía
        led_notif      <= '0';  -- LED notificación
        led_sobrecarga <= '0'; -- LED sobrecarga
        buzz_1khz      <= '0'; -- Tono bajo (1kHz)
        buzz_2khz      <= '0'; -- Tono alto (2kHz)
        
        -- Activación condicional según estado actual
        case state is
            when IDLE =>  -- Estado inactivo
                null;  -- Todas las salidas permanecen en 0
                
            when APERTURA_PUERTA =>  -- Alarma apertura puerta
                led_puerta_abi <= '1';  -- LED puerta abierta encendido
                buzz_1khz      <= '1';  -- Tono continuo de 1kHz
                
            when CIERRE_PUERTA =>  -- Alarma cierre puerta
                led_puerta_cie <= '1';  -- LED puerta cerrada encendido
                buzz_2khz      <= '1';  -- Tono continuo de 2kHz
                
            when ALARMA_SOBRECARGA =>  -- Alarma por sobrecarga
                -- Patrón intermitente: 200ms ON, 200ms OFF
                if contador_200ms < 5000000 then  -- Primeros 200ms
                    led_sobrecarga <= '1';  -- LED encendido
                    buzz_2khz <= '1';       -- Tono alto activo
                end if;
                
            when ALARMA_NOTIFICACION =>  -- Alarma por notificación
                -- Patrón intermitente: 500ms ON, 500ms OFF
                if contador_500ms < 12500000 then  -- Primeros 500ms
                    led_notif <= '1';  -- LED encendido
                    buzz_1khz <= '1';  -- Tono bajo activo
                end if;
                
            when ALARMA_FALLO_ENERGIA =>  -- Alarma por fallo de energía
                -- Patrón intermitente: 1s ON, 1s OFF
                if contador_500ms < 12500000 then  -- Primeros 1s (mitad del contador)
                    led_fallo_en <= '1';  -- LED encendido
                    buzz_2khz <= '1';     -- Tono alto activo
                end if;
        end case;
    end process;

    ------------------------------------------------------------------------
    -- GENERACIÓN DE LA SALIDA DEL BUZZER
    ------------------------------------------------------------------------
    
    -- El buzzer mezcla los dos tonos (1kHz y 2kHz) según las señales de control
    buzzer <= (buzz_1khz and clk_1khz) or (buzz_2khz and clk_2khz);

end Behavioral;