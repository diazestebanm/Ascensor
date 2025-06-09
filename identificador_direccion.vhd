-- =============================================================================
-- Identificador de Dirección para un Sistema de Ascensor
-- 
-- Este módulo determina el próximo piso destino del ascensor basado en:
--   - Estado actual (detenido, subiendo, bajando)
--   - Solicitudes externas (subir, bajar, cabina)
--   - Posición actual del ascensor
-- 
-- Utiliza un algoritmo de búsqueda del piso más cercano con priorización por dirección.
-- =============================================================================

-- Librerías estándar para operaciones lógicas y numéricas
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Definición de la entidad principal
entity identificador_direccion is
    Port (
        -- Reloj de 1Hz para sincronización
        clk_1Hz             : in  STD_LOGIC;
        -- Reset global (activo en alto)
        reset               : in  STD_LOGIC;
        -- Señal del sensor de piso actual (000 = entre pisos)
        piso_actual_sensor  : in  STD_LOGIC_VECTOR(2 downto 0);
        -- Indicador de motor subiendo (activo en alto)
        motor_subir         : in  STD_LOGIC;
        -- Indicador de motor bajando (activo en alto)
        motor_bajar         : in  STD_LOGIC;
        -- Vector de solicitudes EXTERNAS para SUBIR (bit 0 = piso 1, bit 4 = piso 5)
        solicitudes_subir   : in  STD_LOGIC_VECTOR(4 downto 0);
        -- Vector de solicitudes EXTERNAS para BAJAR (bit 0 = piso 1, bit 4 = piso 5)
        solicitudes_bajar   : in  STD_LOGIC_VECTOR(4 downto 0);
        -- Vector de solicitudes INTERNAS de la CABINA (bit 0 = piso 1, bit 4 = piso 5)
        solicitudes_cabina  : in  STD_LOGIC_VECTOR(4 downto 0);
        -- Próximo piso destino calculado
        piso_destino        : out STD_LOGIC_VECTOR(2 downto 0)
    );
end identificador_direccion;

-- Implementación de la arquitectura
architecture Behavioral of identificador_direccion is
    -- Definición de los estados del ascensor
    type estado_ascensor is (
        DETENIDO,   -- Ascensor detenido
        SUBIENDO,   -- Ascensor moviéndose hacia arriba
        BAJANDO     -- Ascensor moviéndose hacia abajo
    );
    
    -- Señales internas
    signal estado_actual          : estado_ascensor := DETENIDO;  -- Estado actual del ascensor
    signal reg_piso_destino       : STD_LOGIC_VECTOR(2 downto 0) := "001";  -- Registro de destino
    signal solicitudes_combinadas : STD_LOGIC_VECTOR(4 downto 0);  -- Solicitudes activas combinadas
    signal last_known_floor       : STD_LOGIC_VECTOR(2 downto 0) := "001";  -- Último piso conocido
    
    -- Constantes para los límites del edificio
    constant PISO_MIN : integer := 1;  -- Piso mínimo (planta baja)
    constant PISO_MAX : integer := 5;  -- Piso máximo

begin
    -- =========================================================================
    -- Combinación de todas las solicitudes activas
    -- OR bit a bit de los tres vectores de solicitudes:
    --   - Solicitudes externas para subir
    --   - Solicitudes externas para bajar
    --   - Solicitudes internas de la cabina
    -- Resultado: Vector donde un '1' indica que hay ALGUNA solicitud en ese piso
    -- =========================================================================
    solicitudes_combinadas <= solicitudes_subir or solicitudes_bajar or solicitudes_cabina;

    -- =========================================================================
    -- Proceso: Registro del último piso conocido
    -- Propósito: Mantener referencia de posición cuando el ascensor está entre pisos
    -- =========================================================================
    process(clk_1Hz, reset)
    begin
        -- Reset asincrónico (activo en alto)
        if reset = '1' then
            -- Valor inicial: Piso 1
            last_known_floor <= "001";
        -- Sincronizado al flanco ascendente del reloj de 1Hz
        elsif rising_edge(clk_1Hz) then
            -- Solo actualizar si el sensor reporta un piso válido (no 000)
            if piso_actual_sensor /= "000" then
                last_known_floor <= piso_actual_sensor;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Proceso: Máquina de Estados de Dirección
    -- Propósito: Determinar el estado actual de movimiento del ascensor
    -- =========================================================================
    process(clk_1Hz, reset)
    begin
        -- Reset asincrónico
        if reset = '1' then
            estado_actual <= DETENIDO;
        -- Sincronizado al flanco ascendente del reloj
        elsif rising_edge(clk_1Hz) then
            -- Prioridad a señales de motor
            if motor_subir = '1' then
                estado_actual <= SUBIENDO;
            elsif motor_bajar = '1' then
                estado_actual <= BAJANDO;
            else
                estado_actual <= DETENIDO;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Proceso: Lógica de Selección de Piso Destino (Algoritmo de Búsqueda)
    -- 
    -- Funcionamiento:
    --   1. Usa el último piso conocido si el sensor reporta "entre pisos" (000)
    --   2. Busca en TODOS los pisos con solicitudes activas
    --   3. Calcula la distancia al piso actual
    --   4. Prioriza pisos en la dirección actual de movimiento (reduce distancia)
    --   5. Selecciona el piso con MENOR distancia efectiva
    --   6. En empates, prioriza la dirección actual
    -- =========================================================================
    process(clk_1Hz)
        -- Variables para cálculo temporal
        variable piso_actual_int : integer range 0 to PISO_MAX;  -- Piso actual en entero
        variable best_floor      : integer range 0 to PISO_MAX;  -- Mejor piso encontrado
        variable min_distance    : integer;  -- Distancia mínima encontrada
        variable current_dist    : integer;  -- Distancia temporal para comparación
    begin
        -- Solo se ejecuta en flanco ascendente del reloj
        if rising_edge(clk_1Hz) then
            -- Lógica para determinar posición actual:
            -- Si el sensor reporta "entre pisos" (000), usar último piso conocido
            -- De lo contrario, usar el valor del sensor directamente
            if piso_actual_sensor = "000" then
                piso_actual_int := to_integer(unsigned(last_known_floor));
            else
                piso_actual_int := to_integer(unsigned(piso_actual_sensor));
            end if;
            
            -- Inicialización de variables de búsqueda:
            best_floor := piso_actual_int;  -- Valor por defecto (piso actual)
            min_distance := PISO_MAX + 1;    -- Distancia inicial (mayor que máxima posible)

            -- Búsqueda en todos los pisos (desde PISO_MIN hasta PISO_MAX)
            for i in PISO_MIN to PISO_MAX loop
                -- Verificar si hay solicitud en el piso 'i'
                if solicitudes_combinadas(i-1) = '1' then  -- Nota: Bit i-1 corresponde al piso i
                    -- Calcular distancia absoluta al piso actual
                    current_dist := abs(piso_actual_int - i);
                    
                    -- Priorización por dirección de movimiento:
                    --   - Si vamos SUBIENDO: dar prioridad a pisos ARRIBA del actual
                    --   - Si vamos BAJANDO: dar prioridad a pisos ABAJO del actual
                    -- Método: Reducir en 1 la distancia efectiva para direcciones coincidentes
                    if estado_actual = SUBIENDO and i > piso_actual_int then
                        current_dist := current_dist - 1;  -- Priorizar pisos hacia arriba
                    elsif estado_actual = BAJANDO and i < piso_actual_int then
                        current_dist := current_dist - 1;  -- Priorizar pisos hacia abajo
                    end if;
                    
                    -- Comparación para encontrar el piso más cercano:
                    if current_dist < min_distance then
                        -- Nuevo mínimo encontrado
                        min_distance := current_dist;
                        best_floor := i;
                    
                    -- Manejo de empates en distancia:
                    --   Priorizar la dirección actual de movimiento
                    elsif current_dist = min_distance then
                        -- Si vamos SUBIENDO y el piso candidato está ARRIBA
                        if estado_actual = SUBIENDO and i > piso_actual_int then
                            best_floor := i;
                        -- Si vamos BAJANDO y el piso candidato está ABAJO
                        elsif estado_actual = BAJANDO and i < piso_actual_int then
                            best_floor := i;
                        end if;
                    end if;
                end if;
            end loop;

            -- Actualización del registro de destino:
            -- Solo si el piso encontrado es válido (dentro de rango) y diferente al actual
            if best_floor >= PISO_MIN and best_floor <= PISO_MAX and best_floor /= piso_actual_int then
                reg_piso_destino <= std_logic_vector(to_unsigned(best_floor, 3));
            end if;
        end if;
    end process;

    -- Asignación continua de la salida
    piso_destino <= reg_piso_destino;

end Behavioral;