LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

package componentes is

	
	component DECOD7 is
		port(
			ABCD	: in  std_logic_vector(3 downto 0);
			DISPLAY	: out std_logic_vector(6 downto 0)
			);
	end component;
	
	component Des2 is
		 generic (
        INPUT_WIDTH : integer := 4 -- Ancho de la entrada (por defecto 4 bits)
    );
    port (
        entrada   : in  STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0); -- Entrada binaria
        unidades  : out STD_LOGIC_VECTOR (3 downto 0);              -- Unidades en BCD
        decenas   : out STD_LOGIC_VECTOR (3 downto 0)               -- Decenas en BCD
    );
	end component;

	component divisor is
    generic (
        DIVISOR : integer := 50_000_000  -- Valor por defecto para dividir un reloj de 50 MHz a 1 Hz
    );
    port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        enable  : in  STD_LOGIC := '1';       -- Permite habilitar o pausar el divisor
        clk_out : out STD_LOGIC
    );
	end component;
	
	component GenericTimer is
    generic (
        MAX_COUNT : integer := 10  -- Duración máxima del temporizador (en segundos)
    );
    port (
        clk_1Hz : in std_logic;  -- Reloj de 1 Hz
        reset   : in std_logic;  -- Reiniciar temporizador
        start   : in std_logic;  -- Iniciar temporizador
        done    : out std_logic  -- Señal de fin de temporización (1 solo ciclo)
    );
	end component;
	
	component RAM is
    generic (
        ADDR_WIDTH : integer := 8;
        DATA_WIDTH : integer := 8
    );
    port (
        clk      : in  STD_LOGIC;
        we       : in  STD_LOGIC;
        address  : in  STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
	end component;
	
	component ContadorPersonas IS
    PORT(
        clk_1Hz        : IN STD_LOGIC;
        reset          : IN STD_LOGIC;
        entrar_persona : IN STD_LOGIC;  -- Corregido typo (persona)
        salir_persona  : IN STD_LOGIC;
        num_personas   : OUT STD_LOGIC_VECTOR(3 downto 0);
        luces          : OUT STD_LOGIC;
        sobrecarga     : OUT STD_LOGIC
    );
	END component;

	
	component Alarmas IS
    PORT(
        clk_50MHz     : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;
        -- Entradas de alarmas
        abrir_puerta  : IN  STD_LOGIC;
        cerrar_puerta : IN  STD_LOGIC;
        fallo_energia : IN  STD_LOGIC;
        notificacion  : IN  STD_LOGIC;
        sobrecarga    : IN  STD_LOGIC;
        -- Salidas
        buzzer        : OUT STD_LOGIC;
        led_puerta_abi: OUT STD_LOGIC;
        led_puerta_cie: OUT STD_LOGIC;
        led_fallo_en  : OUT STD_LOGIC;
        led_notif     : OUT STD_LOGIC;
        led_sobrecarga: OUT STD_LOGIC
    );
	END component;
	
	component Solicitudes is
    Port (
        clk_1Hz               : in  STD_LOGIC;                     -- Reloj de 1 Hz
        reset                 : in  STD_LOGIC;                     -- Reset global
        -- Entradas de botones
        botones_cabina        : in  STD_LOGIC_VECTOR(4 downto 0);  -- Botones internos (Pisos 1-5)
        BOTON_SUBIR           : in  STD_LOGIC_VECTOR(3 downto 0);  -- Botones SUBIR externos (Pisos 1-4)
        BOTON_BAJAR           : in  STD_LOGIC_VECTOR(3 downto 0);  -- Botones BAJAR externos (Pisos 2-5)
        piso_actual           : in  STD_LOGIC_VECTOR(2 downto 0);  -- Piso actual del ascensor (0-4 para pisos 1-5)
        piso_destino          : in  STD_LOGIC_VECTOR(2 downto 0);  -- Piso destino para autolimpieza
        -- Salidas de solicitudes
        solicitudes_internas  : out STD_LOGIC_VECTOR(4 downto 0); -- Solicitudes internas activas
        solicitudes_subir     : out STD_LOGIC_VECTOR(3 downto 0); -- Solicitudes SUBIR activas
        solicitudes_bajar     : out STD_LOGIC_VECTOR(3 downto 0)  -- Solicitudes BAJAR activas
    );
	END component;
	
	component identificador_direccion is
    Port (
        clk_1Hz             : in  STD_LOGIC;
        reset               : in  STD_LOGIC;
        piso_actual_sensor  : in  STD_LOGIC_VECTOR(2 downto 0);  -- Piso actual (1-5)
        motor_subir         : in  STD_LOGIC;                     -- '1' si el ascensor está subiendo
        motor_bajar         : in  STD_LOGIC;                     -- '1' si el ascensor está bajando
        solicitudes_subir   : in  STD_LOGIC_VECTOR(4 downto 0);  -- Bitmap de pisos que quieren subir (piso 1 a 5)
        solicitudes_bajar   : in  STD_LOGIC_VECTOR(4 downto 0);  -- Bitmap de pisos que quieren bajar (piso 1 a 5)
        solicitudes_cabina  : in  STD_LOGIC_VECTOR(4 downto 0);  -- Bitmap de pisos seleccionados en la cabina
        piso_destino        : out STD_LOGIC_VECTOR(2 downto 0)   -- Piso destino (1-5)r
    );
	END component;
	
	component Control_Motor is
    Port (
        -- Entradas generales
        clk_50MHz    : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        -- Entradas de control
        abrir_puerta : in  STD_LOGIC;
        cerrar_puerta: in  STD_LOGIC;
        subir        : in  STD_LOGIC;
        bajar        : in  STD_LOGIC;
        -- Salidas para el motor de puerta
        puerta_A     : out STD_LOGIC;
        puerta_B     : out STD_LOGIC;
        puerta_EN    : out STD_LOGIC;
        -- Salidas para el motor de elevación
        elevacion_A  : out STD_LOGIC;
        elevacion_B  : out STD_LOGIC
    );
	END component;
	
	component infrarrojo_personas is
    Port (
        clk          : in  STD_LOGIC;      -- Reloj del sistema 1hz
        reset        : in  STD_LOGIC;      -- Reset activo alto
        sensor_ext   : in  STD_LOGIC;      -- Sensor externo (entrada)
        sensor_int   : in  STD_LOGIC;      -- Sensor interno (salida)
        person_in    : out STD_LOGIC;      -- Pulso cuando entra una persona
        person_out   : out STD_LOGIC       -- Pulso cuando sale una persona
    );
	END component;

end componentes;