LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entidad del contador de personas para ascensor
ENTITY ContadorPersonas IS
    PORT(
        clk_1Hz        : IN STD_LOGIC;         -- Reloj de 1 Hz para sincronización
        reset          : IN STD_LOGIC;          -- Reset asíncrono (activo alto)
        entrar_persona : IN STD_LOGIC;          -- Señal que indica que entra una persona (flanco ascendente)
        salir_persona  : IN STD_LOGIC;          -- Señal que indica que sale una persona (flanco ascendente)
        num_personas   : OUT STD_LOGIC_VECTOR(3 downto 0); -- Número actual de personas (0-10)
        luces          : OUT STD_LOGIC;         -- Control de luces: '1' = luces encendidas, '0' = apagadas
        sobrecarga     : OUT STD_LOGIC          -- Indicador de sobrecarga: '1' cuando hay >10 personas
    );
END ContadorPersonas;

ARCHITECTURE Behavioral OF ContadorPersonas IS
    -- Definición de estados: cada estado representa un conteo específico de personas
    TYPE estado_type IS (
        E0,           -- 0 personas
        E1,           -- 1 persona
        E2,           -- 2 personas
        E3,           -- 3 personas
        E4,           -- 4 personas
        E5,           -- 5 personas
        E6,           -- 6 personas
        E7,           -- 7 personas
        E8,           -- 8 personas
        E9,           -- 9 personas
        E10,          -- 10 personas
        E_SOBRECARGA  -- Más de 10 personas (estado de sobrecarga)
    );
    
    -- Señales para la máquina de estados
    SIGNAL estado_actual, proximo_estado : estado_type;
    
    -- Función para convertir el estado actual en valor binario (salida num_personas)
    FUNCTION estado_a_binario(e: estado_type) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE e IS
            WHEN E0           => RETURN "0000"; -- 0 personas
            WHEN E1           => RETURN "0001"; -- 1 persona
            WHEN E2           => RETURN "0010"; -- 2 personas
            WHEN E3           => RETURN "0011"; -- 3 personas
            WHEN E4           => RETURN "0100"; -- 4 personas
            WHEN E5           => RETURN "0101"; -- 5 personas
            WHEN E6           => RETURN "0110"; -- 6 personas
            WHEN E7           => RETURN "0111"; -- 7 personas
            WHEN E8           => RETURN "1000"; -- 8 personas
            WHEN E9           => RETURN "1001"; -- 9 personas
            WHEN E10          => RETURN "1010"; -- 10 personas
            WHEN E_SOBRECARGA => RETURN "1010"; -- En sobrecarga muestra 10 (límite del contador)
        END CASE;
    END FUNCTION;
    
    -- Función para controlar la señal de luces
    FUNCTION control_luces(e: estado_type) RETURN STD_LOGIC IS
    BEGIN
        CASE e IS
            WHEN E0 => RETURN '0'; -- Luces apagadas cuando no hay personas
            WHEN OTHERS => RETURN '1'; -- Luces encendidas cuando hay al menos 1 persona
        END CASE;
    END FUNCTION;
    
    -- Función para controlar la señal de sobrecarga
    FUNCTION control_sobrecarga(e: estado_type) RETURN STD_LOGIC IS
    BEGIN
        CASE e IS
            WHEN E_SOBRECARGA => RETURN '1'; -- Activa sobrecarga solo en este estado
            WHEN OTHERS => RETURN '0';       -- Sin sobrecarga en otros estados
        END CASE;
    END FUNCTION;
    
BEGIN
    -- Proceso de sincronización: maneja transiciones de estado en flanco de reloj
    PROC_SINC: PROCESS(clk_1Hz, reset)
    BEGIN
        IF reset = '1' THEN
            -- Reset asíncrono: vuelve al estado inicial (0 personas)
            estado_actual <= E0;
        ELSIF rising_edge(clk_1Hz) THEN
            -- En cada flanco ascendente de reloj, actualiza el estado actual
            estado_actual <= proximo_estado;
        END IF;
    END PROCESS;

    -- Proceso de lógica de estado siguiente: determina transiciones basado en entradas
    LOGICA_ESTADO: PROCESS(estado_actual, entrar_persona, salir_persona)
    BEGIN
        -- Valor por defecto: mantiene el estado actual
        proximo_estado <= estado_actual;
        
        -- Máquina de estados: define transiciones para cada estado posible
        CASE estado_actual IS
            WHEN E0 => -- Estado 0 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E1; -- Entra 1 persona
                END IF;
                
            WHEN E1 => -- Estado 1 persona
                IF entrar_persona = '1' THEN
                    proximo_estado <= E2; -- Entra otra persona (total 2)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E0; -- Sale 1 persona (total 0)
                END IF;
                
            WHEN E2 => -- Estado 2 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E3; -- Entra persona (total 3)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E1; -- Sale persona (total 1)
                END IF;
                
            WHEN E3 => -- Estado 3 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E4; -- Entra persona (total 4)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E2; -- Sale persona (total 2)
                END IF;
                
            WHEN E4 => -- Estado 4 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E5; -- Entra persona (total 5)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E3; -- Sale persona (total 3)
                END IF;
                
            WHEN E5 => -- Estado 5 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E6; -- Entra persona (total 6)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E4; -- Sale persona (total 4)
                END IF;
                
            WHEN E6 => -- Estado 6 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E7; -- Entra persona (total 7)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E5; -- Sale persona (total 5)
                END IF;
                
            WHEN E7 => -- Estado 7 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E8; -- Entra persona (total 8)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E6; -- Sale persona (total 6)
                END IF;
                
            WHEN E8 => -- Estado 8 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E9; -- Entra persona (total 9)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E7; -- Sale persona (total 7)
                END IF;
                
            WHEN E9 => -- Estado 9 personas
                IF entrar_persona = '1' THEN
                    proximo_estado <= E10; -- Entra persona (total 10)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E8; -- Sale persona (total 8)
                END IF;
                
            WHEN E10 => -- Estado 10 personas (capacidad máxima normal)
                IF entrar_persona = '1' THEN
                    proximo_estado <= E_SOBRECARGA; -- Entra persona (sobrecarga)
                ELSIF salir_persona = '1' THEN
                    proximo_estado <= E9; -- Sale persona (total 9)
                END IF;
                
            WHEN E_SOBRECARGA => -- Estado de sobrecarga (>10 personas)
                IF salir_persona = '1' THEN
                    proximo_estado <= E10; -- Sale persona (vuelve a capacidad máxima)
                END IF;
                -- Nota: No se permiten más entradas en estado de sobrecarga
        END CASE;
    END PROCESS;

    -- Asignación de salidas:
    num_personas <= estado_a_binario(estado_actual); -- Convierte estado a número binario
    luces <= control_luces(estado_actual);           -- Control de encendido/apagado de luces
    sobrecarga <= control_sobrecarga(estado_actual); -- Indicador de sobrecarga

END Behavioral;