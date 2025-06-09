library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.componentes.all;  -- Incluye componentes personalizados del proyecto

-- Entidad principal del sistema de gestión de solicitudes de ascensor
entity Solicitudes is
    Port (
        -- Entradas de reloj y reset
        clk_1Hz               : in  STD_LOGIC;  -- Reloj de 1 Hz para sincronización
        reset                 : in  STD_LOGIC;  -- Señal de reset global
        
        -- Entradas de botones
        botones_cabina        : in  STD_LOGIC_VECTOR(4 downto 0);  -- Botones internos (pisos 1-5)
        BOTON_SUBIR           : in  STD_LOGIC_VECTOR(3 downto 0);  -- Botones externos SUBIR (pisos 1-4)
        BOTON_BAJAR           : in  STD_LOGIC_VECTOR(3 downto 0);  -- Botones externos BAJAR (pisos 2-5)
        
        -- Entradas de posición
        piso_actual           : in  STD_LOGIC_VECTOR(2 downto 0);  -- Piso actual del ascensor (1-5)
        piso_destino          : in  STD_LOGIC_VECTOR(2 downto 0);  -- Piso destino actual
        
        -- Salidas de estado de solicitudes
        solicitudes_internas  : out STD_LOGIC_VECTOR(4 downto 0);  -- Registro de solicitudes internas activas
        solicitudes_subir     : out STD_LOGIC_VECTOR(3 downto 0);  -- Registro de solicitudes SUBIR activas
        solicitudes_bajar     : out STD_LOGIC_VECTOR(3 downto 0)   -- Registro de solicitudes BAJAR activas
    );
end Solicitudes;

architecture Behavioral of Solicitudes is
    -- Constantes para direcciones de memoria RAM
    constant DIR_INTERNAS : std_logic_vector(7 downto 0) := x"00";  -- Dirección RAM para solicitudes internas
    constant DIR_SUBIR    : std_logic_vector(7 downto 0) := x"01";  -- Dirección RAM para solicitudes SUBIR
    constant DIR_BAJAR    : std_logic_vector(7 downto 0) := x"02";  -- Dirección RAM para solicitudes BAJAR
    
    -- Definición de estados de la máquina de estados finitos (FSM)
    type estado_type is (
        INICIO,                 -- Estado inicial
        INICIALIZAR_RAM_0,       -- Inicializa RAM para solicitudes internas
        INICIALIZAR_RAM_1,       -- Inicializa RAM para solicitudes SUBIR
        INICIALIZAR_RAM_2,       -- Inicializa RAM para solicitudes BAJAR
        DETECTAR_PULSOS,         -- Estado para iniciar detección de pulsos
        LEER_RAM_INTERNAS,       -- Inicia lectura de RAM para solicitudes internas
        ESPERAR_LECTURA_INTERNAS,-- Espera dato de RAM para solicitudes internas
        LEER_RAM_SUBIR,          -- Inicia lectura de RAM para solicitudes SUBIR
        ESPERAR_LECTURA_SUBIR,   -- Espera dato de RAM para solicitudes SUBIR
        LEER_RAM_BAJAR,          -- Inicia lectura de RAM para solicitudes BAJAR
        ESPERAR_LECTURA_BAJAR,   -- Espera dato de RAM para solicitudes BAJAR
        ACTUALIZAR_REGISTROS,    -- Actualiza registros con nuevas solicitudes
        VERIFICAR_DESTINO,       -- Verifica si se llegó al piso destino
        ESCRIBIR_RAM_INTERNAS,   -- Escribe registro actualizado en RAM internas
        ESCRIBIR_RAM_SUBIR,      -- Escribe registro actualizado en RAM SUBIR
        ESCRIBIR_RAM_BAJAR       -- Escribe registro actualizado en RAM BAJAR
    );
    signal estado_actual : estado_type := INICIO;  -- Registro de estado actual

    -- Señales para interfaz con memoria RAM
    signal ram_data_out : STD_LOGIC_VECTOR(7 downto 0);  -- Dato leído de RAM
    signal ram_we       : STD_LOGIC := '0';             -- Write Enable para RAM
    signal ram_address  : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');  -- Dirección RAM
    signal ram_data_in  : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');  -- Dato a escribir en RAM

    -- Registros para almacenar el estado de las solicitudes
    signal reg_solicitudes : STD_LOGIC_VECTOR(4 downto 0) := (others=>'0');  -- Solicitudes internas
    signal reg_subir       : STD_LOGIC_VECTOR(3 downto 0) := (others=>'0');  -- Solicitudes SUBIR
    signal reg_bajar       : STD_LOGIC_VECTOR(3 downto 0) := (others=>'0');  -- Solicitudes BAJAR

    -- Registros para detección de flancos ascendentes (botones pulsados)
    signal boton_prev      : STD_LOGIC_VECTOR(4 downto 0) := (others=>'0');  -- Estado previo botones cabina
    signal subir_prev      : STD_LOGIC_VECTOR(3 downto 0) := (others=>'0');  -- Estado previo botones SUBIR
    signal bajar_prev      : STD_LOGIC_VECTOR(3 downto 0) := (others=>'0');  -- Estado previo botones BAJAR
    
    -- Registros temporales para datos leídos de RAM
    signal reg_internas_ram : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');  -- Buffer RAM internas
    signal reg_subir_ram    : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');  -- Buffer RAM SUBIR
    signal reg_bajar_ram    : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');  -- Buffer RAM BAJAR

begin
    -- Instanciación de memoria RAM (componente externo)
    RAM_Inst : RAM
    generic map(
        ADDR_WIDTH => 8,   -- Ancho de dirección: 8 bits (256 posiciones)
        DATA_WIDTH => 8    -- Ancho de dato: 8 bits
    )
    port map(
        clk      => clk_1Hz,     -- Reloj de 1 Hz
        we       => ram_we,      -- Señal de habilitación de escritura
        address  => ram_address, -- Dirección de memoria
        data_in  => ram_data_in, -- Dato de entrada
        data_out => ram_data_out -- Dato de salida
    );

    -- Proceso principal: Máquina de Estados Finitos (FSM) y lógica de control
    process(clk_1Hz, reset)
    begin
        -- Reset asíncrono (alta prioridad)
        if reset = '1' then
            -- Reinicio de todos los registros y señales
            estado_actual <= INICIO;
            reg_solicitudes <= (others=>'0');
            reg_subir <= (others=>'0');
            reg_bajar <= (others=>'0');
            boton_prev <= (others=>'0');
            subir_prev <= (others=>'0');
            bajar_prev <= (others=>'0');
            ram_we <= '0';
            ram_address <= (others=>'0');
            ram_data_in <= (others=>'0');
            reg_internas_ram <= (others=>'0');
            reg_subir_ram <= (others=>'0');
            reg_bajar_ram <= (others=>'0');
            
        -- Comportamiento en flanco ascendente de reloj
        elsif rising_edge(clk_1Hz) then
            -- Registro de estados previos para detección de flancos
            boton_prev <= botones_cabina;  -- Almacena estado actual para próximo ciclo
            subir_prev <= BOTON_SUBIR;
            bajar_prev <= BOTON_BAJAR;
            
            -- Valor por defecto (evita inferencia de latch)
            ram_we <= '0';  -- Por defecto no escribir en RAM

            -- Máquina de Estados Principal
            case estado_actual is
                when INICIO =>
                    -- Estado inicial: transición a primera operación de inicialización
                    estado_actual <= INICIALIZAR_RAM_0;
                    
                when INICIALIZAR_RAM_0 =>
                    -- Inicialización de RAM para solicitudes internas (dirección 00)
                    ram_we <= '1';              -- Habilita escritura
                    ram_address <= DIR_INTERNAS;-- Dirección 00
                    ram_data_in <= x"00";       -- Valor 00 (todas solicitudes apagadas)
                    estado_actual <= INICIALIZAR_RAM_1;  -- Siguiente estado
                    
                when INICIALIZAR_RAM_1 =>
                    -- Inicialización de RAM para solicitudes SUBIR (dirección 01)
                    ram_we <= '1';           -- Habilita escritura
                    ram_address <= DIR_SUBIR;-- Dirección 01
                    ram_data_in <= x"00";    -- Valor 00
                    estado_actual <= INICIALIZAR_RAM_2;  -- Siguiente estado
                    
                when INICIALIZAR_RAM_2 =>
                    -- Inicialización de RAM para solicitudes BAJAR (dirección 02)
                    ram_we <= '1';           -- Habilita escritura
                    ram_address <= DIR_BAJAR;-- Dirección 02
                    ram_data_in <= x"00";    -- Valor 00
                    estado_actual <= DETECTAR_PULSOS;  -- Siguiente estado: operación normal
                
                when DETECTAR_PULSOS =>
                    -- Prepara lectura de RAM para solicitudes internas
                    ram_address <= DIR_INTERNAS;  -- Dirección 00
                    estado_actual <= LEER_RAM_INTERNAS;  -- Siguiente estado
                
                when LEER_RAM_INTERNAS =>
                    -- Estado de espera para sincronización con RAM (1 ciclo de reloj)
                    estado_actual <= ESPERAR_LECTURA_INTERNAS;
                    
                when ESPERAR_LECTURA_INTERNAS =>
                    -- Captura dato leído de RAM para solicitudes internas
                    reg_internas_ram <= ram_data_out;  -- Almacena en buffer
                    ram_address <= DIR_SUBIR;          -- Prepara próxima dirección
                    estado_actual <= LEER_RAM_SUBIR;   -- Siguiente estado
                    
                when LEER_RAM_SUBIR =>
                    -- Estado de espera para lectura RAM SUBIR
                    estado_actual <= ESPERAR_LECTURA_SUBIR;
                    
                when ESPERAR_LECTURA_SUBIR =>
                    -- Captura dato leído de RAM para solicitudes SUBIR
                    reg_subir_ram <= ram_data_out;    -- Almacena en buffer
                    ram_address <= DIR_BAJAR;         -- Prepara próxima dirección
                    estado_actual <= LEER_RAM_BAJAR;  -- Siguiente estado
                    
                when LEER_RAM_BAJAR =>
                    -- Estado de espera para lectura RAM BAJAR
                    estado_actual <= ESPERAR_LECTURA_BAJAR;
                    
                when ESPERAR_LECTURA_BAJAR =>
                    -- Captura dato leído de RAM para solicitudes BAJAR
                    reg_bajar_ram <= ram_data_out;    -- Almacena en buffer
                    estado_actual <= ACTUALIZAR_REGISTROS;  -- Siguiente estado
                
                when ACTUALIZAR_REGISTROS =>
                    -- Actualiza registros con nuevos pulsos detectados por flancos
                    -- Combinación de estado guardado en RAM y nuevos pulsos:
                    reg_solicitudes <= reg_internas_ram(4 downto 0) or (botones_cabina and not boton_prev);
                    reg_subir <= reg_subir_ram(3 downto 0) or (BOTON_SUBIR and not subir_prev);
                    reg_bajar <= reg_bajar_ram(3 downto 0) or (BOTON_BAJAR and not bajar_prev);
                    estado_actual <= VERIFICAR_DESTINO;  -- Siguiente estado
                
                when VERIFICAR_DESTINO =>
                    -- Lógica para borrar solicitudes cuando el ascensor llega al piso destino
                    if piso_actual = piso_destino and piso_actual /= "000" then
                        -- Borra solicitud interna del piso actual (bits 0-4)
                        reg_solicitudes(to_integer(unsigned(piso_actual))-1) <= '0';
                        
                        -- Borra solicitud SUBIR si el piso está en rango (pisos 1-4)
                        if unsigned(piso_actual) >= 1 and unsigned(piso_actual) <= 4 then
                            -- Nota: Los botones SUBIR están indexados desde piso 1 (bit 0)
                            reg_subir(to_integer(unsigned(piso_actual))-1) <= '0';
                        end if;
                        
                        -- Borra solicitud BAJAR si el piso está en rango (pisos 2-5)
                        if unsigned(piso_actual) >= 2 and unsigned(piso_actual) <= 5 then
                            -- Nota: Los botones BAJAR están indexados desde piso 2 (bit 0)
                            reg_bajar(to_integer(unsigned(piso_actual))-2) <= '0';
                        end if;
                    end if;
                    estado_actual <= ESCRIBIR_RAM_INTERNAS;  -- Siguiente estado
                
                when ESCRIBIR_RAM_INTERNAS =>
                    -- Escribe registro actualizado en RAM para solicitudes internas
                    ram_we <= '1';                  -- Habilita escritura
                    ram_address <= DIR_INTERNAS;     -- Dirección 00
                    ram_data_in <= "000" & reg_solicitudes;  -- Formato 8 bits (3 MSB + 5 bits)
                    estado_actual <= ESCRIBIR_RAM_SUBIR;  -- Siguiente estado
                    
                when ESCRIBIR_RAM_SUBIR =>
                    -- Escribe registro actualizado en RAM para solicitudes SUBIR
                    ram_we <= '1';                -- Habilita escritura
                    ram_address <= DIR_SUBIR;      -- Dirección 01
                    ram_data_in <= "0000" & reg_subir;  -- Formato 8 bits (4 MSB + 4 bits)
                    estado_actual <= ESCRIBIR_RAM_BAJAR;  -- Siguiente estado
                    
                when ESCRIBIR_RAM_BAJAR =>
                    -- Escribe registro actualizado en RAM para solicitudes BAJAR
                    ram_we <= '1';                -- Habilita escritura
                    ram_address <= DIR_BAJAR;      -- Dirección 02
                    ram_data_in <= "0000" & reg_bajar;  -- Formato 8 bits (4 MSB + 4 bits)
                    estado_actual <= DETECTAR_PULSOS;  -- Vuelve al inicio del ciclo
            end case;
        end if;
    end process;

    -- Asignación de salidas: conecta registros internos con puertos de salida
    solicitudes_internas <= reg_solicitudes;  -- Solicitudes internas activas
    solicitudes_subir <= reg_subir;           -- Solicitudes SUBIR activas
    solicitudes_bajar <= reg_bajar;           -- Solicitudes BAJAR activas
end Behavioral;