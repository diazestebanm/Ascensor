-- Archivo: Ascensor.vhd
-- Descripción: Este archivo implementa el control de un sistema de ascensor con gestión de movimiento, puertas, alarmas y visualización.

-- Bibliotecas estándar utilizadas
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE work.componentes.all;  -- Componentes personalizados del proyecto

-- Entidad principal del ascensor
ENTITY Ascensor IS
    PORT(
        -- Entradas del sistema
        clk_50MHz       : IN  STD_LOGIC;  -- Reloj principal de 50 MHz
        reset           : IN  STD_LOGIC;  -- Señal de reset global
        
        -- Botones de control
        boton_subir     : IN  STD_LOGIC_VECTOR(3 downto 0);  -- Botones EXTERNOS para subir (pisos 1-4)
        boton_bajar     : IN  STD_LOGIC_VECTOR(4 downto 1);  -- Botones EXTERNOS para bajar (pisos 2-5)
        boton_cabina    : IN  STD_LOGIC_VECTOR(4 downto 0);  -- Botones INTERNOS de la cabina (pisos 1-5)
        boton_abrir     : IN  STD_LOGIC;  -- Botón para forzar apertura de puertas
        boton_cerrar    : IN  STD_LOGIC;  -- Botón para forzar cierre de puertas
        boton_notif     : IN  STD_LOGIC;  -- Botón de notificación/alarma
        
        -- Sensores del sistema
        sensor_entrada  : IN  STD_LOGIC;  -- Sensor de entrada de personas
        sensor_salida   : IN  STD_LOGIC;  -- Sensor de salida de personas
        piso_sensor     : IN  STD_LOGIC_VECTOR(4 downto 0);  -- One-Hot (activo en '0'): indica el piso actual
        fin_puerta_abierta : IN STD_LOGIC;  -- Señal que indica que la puerta está completamente abierta (activo en '0')
        fin_puerta_cerrada : IN STD_LOGIC;  -- Señal que indica que la puerta está completamente cerrada (activo en '0')
        
        -- Salidas de control de motores
        motor_subir     : OUT STD_LOGIC;  -- Control motor subida
        motor_bajar     : OUT STD_LOGIC;  -- Control motor bajada
        motor_puerta_A  : OUT STD_LOGIC;  -- Control motor puerta (fase A)
        motor_puerta_B  : OUT STD_LOGIC;  -- Control motor puerta (fase B)
        motor_puerta_EN : OUT STD_LOGIC;  -- Enable motor puerta
        
        -- Salidas para displays de 7 segmentos
        disp_pers_dec   : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display decenas (personas)
        disp_pers_uni   : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display unidades (personas)
        disp_cabina     : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display piso actual (cabina)
        disp_piso1      : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display piso 1
        disp_piso2      : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display piso 2
        disp_piso3      : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display piso 3
        disp_piso4      : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display piso 4
        disp_piso5      : OUT STD_LOGIC_VECTOR(6 downto 0);  -- Display piso 5
        
        -- Alarmas y señales de estado
        buzzer          : OUT STD_LOGIC;  -- Zumbador de alerta
        luces_cabina    : OUT STD_LOGIC;  -- Luces internas de la cabina
        clk_l          : OUT STD_LOGIC;  -- Salida de reloj de 1Hz para depuración
        led_puerta_abierta  : OUT STD_LOGIC;  -- LED puerta abierta
        led_puerta_cerrada  : OUT STD_LOGIC;  -- LED puerta cerrada
        led_fallo_energia   : OUT STD_LOGIC;  -- LED fallo de energía
        led_notificacion    : OUT STD_LOGIC;  -- LED notificación activa
        led_sobrecarga      : OUT STD_LOGIC;  -- LED sobrecarga
        sim_fallo_energia   : IN  STD_LOGIC   -- Simulación de fallo de energía
    );
END Ascensor;

-- Arquitectura del ascensor (implementación)
ARCHITECTURE Behavioral OF Ascensor IS
    -- Señales de reloj y temporización
    signal clk_1Hz          : STD_LOGIC;  -- Reloj de 1Hz derivado de 50MHz
    signal num_personas     : STD_LOGIC_VECTOR(3 downto 0);  -- Número de personas en cabina (4 bits)
    signal sobrecarga       : STD_LOGIC;   -- Indicador de sobrecarga (1 = sobrecarga)

    -- Señales de control de movimiento y puertas
    signal abrir_puerta     : STD_LOGIC := '0';  -- Orden de apertura de puertas
    signal cerrar_puerta    : STD_LOGIC := '0';  -- Orden de cierre de puertas
    signal subir_ascensor   : STD_LOGIC := '0';  -- Orden de movimiento ascendente
    signal bajar_ascensor   : STD_LOGIC := '0';  -- Orden de movimiento descendente

    -- Señales de alarmas
    signal fallo_energia    : STD_LOGIC := '0';   -- Estado de fallo de energía
    signal alarma_abrir_puerta : STD_LOGIC := '0';  -- Alarma durante apertura forzada
    signal alarma_cerrar_puerta : STD_LOGIC := '0'; -- Alarma durante cierre forzado

    -- Señales de gestión de pisos
    signal piso_actual_bin  : STD_LOGIC_VECTOR(2 downto 0) := "000";  -- Piso actual (binario)
    signal piso_destino_bin : STD_LOGIC_VECTOR(2 downto 0);  -- Piso destino (binario)
    
    -- Registros de solicitudes
    signal solicitudes_internas : STD_LOGIC_VECTOR(4 downto 0);  -- Solicitudes internas (cabina)
    signal solicitudes_subir    : STD_LOGIC_VECTOR(3 downto 0);  -- Solicitudes externas SUBIR
    signal solicitudes_bajar    : STD_LOGIC_VECTOR(3 downto 0);  -- Solicitudes externas BAJAR

    -- Señales para visualización
    signal bcd_pers_uni     : STD_LOGIC_VECTOR(3 downto 0);  -- Unidades de personas (BCD)
    signal bcd_pers_dec     : STD_LOGIC_VECTOR(3 downto 0);  -- Decenas de personas (BCD)
    signal display_piso_val : STD_LOGIC_VECTOR(3 downto 0);  -- Valor para display de piso

    -- Temporizadores para control de puertas
    signal timer_apertura_start : STD_LOGIC := '0';  -- Inicia temporizador apertura
    signal timer_apertura_done  : STD_LOGIC := '0';  -- Fin temporización apertura
    signal timer_cierre_start   : STD_LOGIC := '0';  -- Inicia temporizador cierre
    signal timer_cierre_done    : STD_LOGIC := '0';  -- Fin temporización cierre
    signal clear_cierre         : STD_LOGIC := '0';  -- Reset temporizador cierre
    signal clear_apertura       : STD_LOGIC := '0';  -- Reset temporizador apertura

    -- Detección de personas
    signal person_in        : STD_LOGIC;  -- Persona detectada entrando
    signal person_out       : STD_LOGIC;  -- Persona detectada saliendo
    
    -- Extensiones de señales de solicitud
    signal solicitudes_subir_ext : STD_LOGIC_VECTOR(4 downto 0);  -- Solicitudes SUBIR extendidas
    signal solicitudes_bajar_ext : STD_LOGIC_VECTOR(4 downto 0);  -- Solicitudes BAJAR extendidas
    signal reset_apertura : STD_LOGIC;  -- Reset combinado para temporizador apertura
    signal reset_cierre : STD_LOGIC;   -- Reset combinado para temporizador cierre

    -- Máquina de estados del ascensor
    type estado_ascensor_type is (
        INICIO,          -- Estado inicial/reset
        ESPERANDO,        -- Esperando solicitudes
        MOVIMIENTO,       -- Ascensor en movimiento
        ESPERA_APERTURA,  -- Espera para abrir puertas
        APERTURA_PUERTA,  -- Proceso de apertura de puertas
        PUERTA_ABIERTA,   -- Puertas completamente abiertas
        CIERRE_PUERTA,    -- Proceso de cierre de puertas
        EMERGENCIA        -- Modo de emergencia (fallo energía)
    );
    signal estado_ascensor : estado_ascensor_type := INICIO;  -- Estado actual

    -- Función: Conversión de codificación one-hot a binario (5 bits -> 3 bits)
    function onehot_to_binary(onehot : std_logic_vector(4 downto 0)) return std_logic_vector is
        variable bin : std_logic_vector(2 downto 0) := "000";  -- Valor por defecto
    begin
        if onehot = "11111" then
            return "000";  -- Valor especial (ningún piso activo)
        else
            -- Escaneo bit a bit para encontrar el '0'
            for i in 0 to 4 loop
                if onehot(i) = '0' then
                    -- Convertir posición one-hot a número binario (i+1)
                    bin := std_logic_vector(to_unsigned(i+1, 3));
                    exit;  -- Salir al encontrar el primer '0'
                end if;
            end loop;
            return bin;
        end if;
    end function;
    
    -- Función: Conversión de binario a one-hot (3 bits -> 5 bits)
    function binary_to_onehot(bin : std_logic_vector(2 downto 0)) return std_logic_vector is
    begin
        case bin is
            when "000"  => return "11111"; -- Ningún piso
            when "001"  => return "11110"; -- Piso 1 (bit 0 = '0')
            when "010"  => return "11101"; -- Piso 2 (bit 1 = '0')
            when "011"  => return "11011"; -- Piso 3 (bit 2 = '0')
            when "100"  => return "10111"; -- Piso 4 (bit 3 = '0')
            when "101"  => return "01111"; -- Piso 5 (bit 4 = '0')
            when others => return "11111"; -- Caso inválido
        end case;
    end function;

begin
    -- Conexión directa de la señal de simulación de fallo de energía
    fallo_energia <= sim_fallo_energia;
    
    -- Extensión de señales de solicitud para alinear índices
    solicitudes_subir_ext <= '1' & solicitudes_subir;  -- Añadir bit 0 (piso 1 no tiene botón SUBIR)
    solicitudes_bajar_ext <= solicitudes_bajar & '1';  -- Añadir bit 4 (piso 5 no tiene botón BAJAR)
    
    -- Reset combinado para temporizadores (reset global OR reset local)
    reset_apertura <= reset or clear_apertura;
    reset_cierre <= reset or clear_cierre;

    ------------------------------------------------------------------------
    -- INSTANCIACIÓN DE COMPONENTES
    ------------------------------------------------------------------------

    -- Divisor de frecuencia: 50MHz -> 1Hz
    div_reloj: entity work.divisor
        generic map(DIVISOR => 50_000_000)  -- Divisor para 1Hz
        port map(
            clk     => clk_50MHz,  -- Entrada de 50MHz
            reset   => reset,       -- Reset síncrono
            clk_out => clk_1Hz      -- Salida de 1Hz
        );
    
    -- Módulo de detección de personas mediante sensores IR
    sensor_personas: entity work.infrarrojo_personas
        port map(
            clk        => clk_1Hz,      -- Reloj de 1Hz
            reset      => reset,         -- Reset
            sensor_ext => sensor_entrada, -- Sensor exterior (entrada)
            sensor_int => sensor_salida,  -- Sensor interior (salida)
            person_in  => person_in,     -- Pulso cuando alguien entra
            person_out => person_out     -- Pulso cuando alguien sale
        );
    
    -- Contador de personas con detección de sobrecarga
    cont_personas: entity work.ContadorPersonas
        port map(
            clk_1Hz         => clk_1Hz,     -- Reloj de 1Hz
            reset           => reset,        -- Reset
            entrar_persona  => person_in,    -- Señal de entrada
            salir_persona   => person_out,   -- Señal de salida
            num_personas    => num_personas, -- Número actual de personas
            luces           => luces_cabina, -- Control luces cabina
            sobrecarga      => sobrecarga    -- Indicador de sobrecarga
        );
    
    -- Convertidor de binario a BCD para display de personas
    personas_bcd: entity work.Des2
        generic map(INPUT_WIDTH => 4)  -- Entrada de 4 bits (0-15)
        port map(
            entrada  => num_personas,  -- Número binario de personas
            unidades => bcd_pers_uni,  -- Dígito unidades (BCD)
            decenas  => bcd_pers_dec   -- Dígito decenas (BCD)
        );
    
    -- Conversión del piso actual (one-hot) a binario
    piso_actual_bin <= onehot_to_binary(piso_sensor);  -- Usa función definida
    
    -- Gestor de solicitudes de pisos (externas e internas)
    gestor_solicitudes: entity work.Solicitudes
        port map(
            clk_1Hz              => clk_1Hz,          -- Reloj de 1Hz
            reset                => reset,             -- Reset
            botones_cabina       => boton_cabina,      -- Botones internos
            BOTON_SUBIR          => boton_subir,       -- Botones externos SUBIR
            BOTON_BAJAR          => boton_bajar,       -- Botones externos BAJAR
            piso_actual          => piso_actual_bin,   -- Piso actual (bin)
            piso_destino         => piso_destino_bin,  -- Piso destino calculado
            solicitudes_internas => solicitudes_internas, -- Registro solicitudes cabina
            solicitudes_subir    => solicitudes_subir,  -- Registro solicitudes SUBIR
            solicitudes_bajar    => solicitudes_bajar   -- Registro solicitudes BAJAR
        );
    
    -- Identificador de dirección de movimiento (subir/bajar)
    ident_direccion: entity work.identificador_direccion
        port map(
            clk_1Hz             => clk_1Hz,          -- Reloj de 1Hz
            reset               => reset,             -- Reset
            piso_actual_sensor  => piso_actual_bin,   -- Piso actual (bin)
            motor_subir         => subir_ascensor,    -- Señal de subida (salida)
            motor_bajar         => bajar_ascensor,    -- Señal de bajada (salida)
            solicitudes_subir   => solicitudes_subir_ext, -- Solicitudes SUBIR extendidas
            solicitudes_bajar   => solicitudes_bajar_ext, -- Solicitudes BAJAR extendidas
            solicitudes_cabina  => solicitudes_internas,  -- Solicitudes cabina
            piso_destino        => piso_destino_bin   -- Piso destino (bin)
        );
    
    -- Temporizador para apertura de puertas (10 segundos)
    timer_apertura: entity work.GenericTimer
        generic map(MAX_COUNT => 10)  -- 10 ciclos de 1Hz = 10 segundos
        port map(
            clk_1Hz => clk_1Hz,          -- Reloj de 1Hz
            reset   => reset_apertura,    -- Reset combinado
            start   => timer_apertura_start,  -- Inicio temporización
            done    => timer_apertura_done    -- Temporización completada
        );
    
    -- Temporizador para cierre de puertas (45 segundos)
    timer_cierre: entity work.GenericTimer
        generic map(MAX_COUNT => 45)  -- 45 ciclos de 1Hz = 45 segundos
        port map(
            clk_1Hz => clk_1Hz,        -- Reloj de 1Hz
            reset   => reset_cierre,    -- Reset combinado
            start   => timer_cierre_start,  -- Inicio temporización
            done    => timer_cierre_done    -- Temporización completada
        );
    
    ------------------------------------------------------------------------
    -- MÁQUINA DE ESTADOS PRINCIPAL (controla el flujo de operación)
    ------------------------------------------------------------------------
    process(clk_1Hz, reset)
        variable dest_onehot : std_logic_vector(4 downto 0);  -- Variable auxiliar
    begin
        if reset = '1' then  -- Reset asíncrono
            -- Estado inicial y señales de control
            estado_ascensor       <= INICIO;  -- Ir a estado inicial
            subir_ascensor        <= '0';     -- Detener motor subida
            bajar_ascensor        <= '0';     -- Detener motor bajada
            abrir_puerta          <= '0';     -- Detener apertura puertas
            cerrar_puerta         <= '0';     -- Detener cierre puertas
            timer_apertura_start  <= '0';     -- Detener temporizador apertura
            timer_cierre_start    <= '0';     -- Detener temporizador cierre
            clear_apertura        <= '0';     -- Reset temporizador apertura
            clear_cierre          <= '0';     -- Reset temporizador cierre
        elsif rising_edge(clk_1Hz) then  -- Flanco ascendente de 1Hz
            -- Valores por defecto para señales de temporización
            timer_apertura_start <= '0';  -- No activar temporizador
            timer_cierre_start   <= '0';  -- No activar temporizador
            clear_apertura       <= '0';  -- No resetear temporizador
            clear_cierre         <= '0';  -- No resetear temporizador
                
            -- Prioridad 1: Fallo de energía (sobre todo lo demás)
            if fallo_energia = '1' then
                estado_ascensor <= EMERGENCIA;  -- Entrar en modo emergencia
                
            -- Prioridad 2: Sobrecarga (detiene movimiento pero no afecta puertas)
            elsif sobrecarga = '1' then
                subir_ascensor <= '0';  -- Detener movimiento ascendente
                bajar_ascensor <= '0';  -- Detener movimiento descendente

            -- Operación normal
            else
                -- Lógica de transición de estados
                case estado_ascensor is
                    when INICIO =>  -- Estado inicial post-reset
                        if fin_puerta_cerrada = '0' then  -- Cambiado a '0'
                            cerrar_puerta <= '0';  -- Desactivar motor cierre
                            alarma_cerrar_puerta <= '1';  -- Indicar cierre completado
                            estado_ascensor <= ESPERANDO;  -- Ir a espera
                        else
                            cerrar_puerta <= '1';  -- Continuar cerrando puertas
                        end if;

                    when ESPERANDO =>  -- Espera de solicitudes
                        subir_ascensor <= '0';  -- Motores detenidos
                        bajar_ascensor <= '0';
                        abrir_puerta <= '0';
                        cerrar_puerta <= '0';
                        
                        -- Si hay un piso destino diferente al actual
                        if piso_destino_bin /= piso_actual_bin and piso_destino_bin /= "000" then
                            estado_ascensor <= MOVIMIENTO;  -- Iniciar movimiento
                        end if;

                    when MOVIMIENTO =>  -- Ascensor en movimiento
                        -- Comprobar si se ha llegado al piso destino
                        if piso_sensor = binary_to_onehot(piso_destino_bin) and piso_sensor /= "11111" then  -- Cambiado a "11111"
                            subir_ascensor <= '0';  -- Detener motores
                            bajar_ascensor <= '0';
                            timer_apertura_start <= '1';  -- Iniciar temporizador apertura
                            estado_ascensor <= ESPERA_APERTURA;  -- Preparar apertura
                        else
                            -- Determinar dirección de movimiento
                            if unsigned(piso_actual_bin) < unsigned(piso_destino_bin) then
                                subir_ascensor <= '1';  -- Mover hacia arriba
                                bajar_ascensor <= '0';
                            else
                                subir_ascensor <= '0';
                                bajar_ascensor <= '1';  -- Mover hacia abajo
                            end if;
                        end if;

                    when ESPERA_APERTURA =>  -- Espera antes de abrir puertas
                        -- Si se pulsa botón abrir o termina temporizador
                        if boton_abrir = '1' or timer_apertura_done = '1' then
                            timer_apertura_start <= '0';  -- Detener temporizador
                            alarma_abrir_puerta <= '1';  -- Activar alarma apertura
                            estado_ascensor <= APERTURA_PUERTA;  -- Abrir puertas
                        end if;

                    when APERTURA_PUERTA =>  -- Proceso de apertura
                        clear_apertura <= '1';  -- Resetear temporizador apertura
                        abrir_puerta <= '1';    -- Activar motor apertura
                        -- Si puerta alcanza posición abierta
                        if fin_puerta_abierta = '0' then  -- Cambiado a '0'
                            abrir_puerta <= '0';        -- Desactivar motor
                            timer_cierre_start <= '1';   -- Iniciar temporizador cierre
                            estado_ascensor <= PUERTA_ABIERTA;  -- Estado puerta abierta
                        end if;

                    when PUERTA_ABIERTA =>  -- Puertas abiertas
                        -- Si se pulsa cerrar o termina temporizador
                        if boton_cerrar = '1' or timer_cierre_done = '1' then
                            timer_cierre_start <= '0';  -- Detener temporizador
                            alarma_cerrar_puerta <= '1';  -- Activar alarma cierre
                            estado_ascensor <= CIERRE_PUERTA;  -- Cerrar puertas
                        end if;

                    when CIERRE_PUERTA =>  -- Proceso de cierre
                        clear_cierre <= '1';   -- Resetear temporizador cierre
                        cerrar_puerta <= '1';  -- Activar motor cierre
                        -- Si puerta alcanza posición cerrada
                        if fin_puerta_cerrada = '0' then  -- Cambiado a '0'
                            cerrar_puerta <= '0';  -- Desactivar motor
                            estado_ascensor <= ESPERANDO;  -- Volver a espera
                        end if;

                    when EMERGENCIA =>  -- Modo de emergencia (fallo energía)
                        subir_ascensor <= '0';  -- Detener movimiento
                        bajar_ascensor <= '0';
                        abrir_puerta <= '0';    -- Cancelar apertura
                        
                        -- Si el ascensor está en un piso válido y la puerta no está cerrada
                        if piso_sensor /= "11111" and fin_puerta_cerrada = '1' then  -- Cambiado a '1'
                            cerrar_puerta <= '1';  -- Intentar cerrar puertas
                        else
                            cerrar_puerta <= '0';  -- Detener cierre
                            alarma_cerrar_puerta <= '1';  -- Indicar cierre completado
                        end if;
                end case;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- INSTANCIACIÓN DE MÓDULOS DE CONTROL
    ------------------------------------------------------------------------

    -- Control de motores (elevación y puertas)
    inst_Control_Motor: entity work.Control_Motor
        port map(
            clk_50MHz     => clk_50MHz,      -- Reloj principal 50MHz
            reset         => reset,           -- Reset global
            abrir_puerta  => boton_abrir,    -- Señal de apertura
            cerrar_puerta => boton_cerrar,   -- Señal de cierre
            subir         => botON_SUBIR(0),  -- Señal de subida
            bajar         => botON_SUBIR(1),  -- Señal de bajada
            puerta_A      => motor_puerta_A,  -- Control fase A motor puerta
            puerta_B      => motor_puerta_B,  -- Control fase B motor puerta
            
            elevacion_A   => motor_subir,     -- Control fase A motor elevación
            elevacion_B   => motor_bajar      -- Control fase B motor elevación
        );

    -- Sistema de alarmas y notificaciones
    sistema_alarmas: entity work.Alarmas
        port map(
            clk_50MHz       => clk_50MHz,        -- Reloj 50MHz
            reset           => reset,             -- Reset
            abrir_puerta    => alarma_abrir_puerta,  -- Alarma apertura forzada
            cerrar_puerta   => alarma_cerrar_puerta, -- Alarma cierre forzado
            fallo_energia   => fallo_energia,    -- Estado fallo energía
            notificacion    => boton_notif,       -- Botón de notificación
            sobrecarga      => sobrecarga,        -- Estado sobrecarga
            buzzer          => buzzer,            -- Salida zumbador
            led_puerta_abi  => led_puerta_abierta,  -- LED puerta abierta
            led_puerta_cie  => led_puerta_cerrada,  -- LED puerta cerrada
            led_fallo_en    => led_fallo_energia, -- LED fallo energía
            led_notif       => led_notificacion,   -- LED notificación
            led_sobrecarga  => led_sobrecarga     -- LED sobrecarga
        );

    ------------------------------------------------------------------------
    -- VISUALIZACIÓN EN DISPLAYS
    ------------------------------------------------------------------------

    -- Preparación de valor para display de piso (extensión a 4 bits)
    display_piso_val <= std_logic_vector(unsigned('0' & piso_actual_bin));  -- "0" & 3 bits
    
    -- Display: Unidades de personas (7 segmentos)
    disp_pers_unidades: entity work.DECOD7 
        port map(
            ABCD => bcd_pers_uni,  -- Entrada BCD (unidades)
            DISPLAY => disp_pers_uni  -- Salida 7 segmentos
        );
    
    -- Display: Decenas de personas (7 segmentos)
    disp_pers_decenas: entity work.DECOD7 
        port map(
            ABCD => bcd_pers_dec,  -- Entrada BCD (decenas)
            DISPLAY => disp_pers_dec  -- Salida 7 segmentos
        );
    
    -- Display: Piso actual en cabina (7 segmentos)
    disp_cabina_inst:  entity work.DECOD7 
        port map(
            ABCD => display_piso_val,  -- Valor del piso (4 bits)
            DISPLAY => disp_cabina      -- Salida 7 segmentos
        );
    
    -- Displays de piso en cada nivel (todos muestran el piso actual)
    disp_piso1_inst:   entity work.DECOD7 
        port map(ABCD => display_piso_val, DISPLAY => disp_piso1);
    disp_piso2_inst:   entity work.DECOD7 
        port map(ABCD => display_piso_val, DISPLAY => disp_piso2);
    disp_piso3_inst:   entity work.DECOD7 
        port map(ABCD => display_piso_val, DISPLAY => disp_piso3);
    disp_piso4_inst:   entity work.DECOD7 
        port map(ABCD => display_piso_val, DISPLAY => disp_piso4);
    disp_piso5_inst:   entity work.DECOD7 
        port map(ABCD => display_piso_val, DISPLAY => disp_piso5);
    
    -- Salida de depuración: reloj de 1Hz
    clk_l <= clk_1Hz;

END Behavioral;

