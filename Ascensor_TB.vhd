LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Ascensor_TB IS
END Ascensor_TB;

ARCHITECTURE Behavioral OF Ascensor_TB IS
    -- Componente del Ascensor
    COMPONENT Ascensor
        PORT(
            clk_50MHz       : IN  STD_LOGIC;
            reset           : IN  STD_LOGIC;
            boton_subir     : IN  STD_LOGIC_VECTOR(3 downto 0);
            boton_bajar     : IN  STD_LOGIC_VECTOR(4 downto 1);
            boton_cabina    : IN  STD_LOGIC_VECTOR(4 downto 0);
            boton_abrir     : IN  STD_LOGIC;
            boton_cerrar    : IN  STD_LOGIC;
            boton_notif     : IN  STD_LOGIC;
            sensor_entrada  : IN  STD_LOGIC;
            sensor_salida   : IN  STD_LOGIC;
            piso_sensor     : IN  STD_LOGIC_VECTOR(4 downto 0);
            fin_puerta_abierta : IN STD_LOGIC;
            fin_puerta_cerrada : IN STD_LOGIC;
            motor_subir     : OUT STD_LOGIC;
            motor_bajar     : OUT STD_LOGIC;
            motor_puerta_A  : OUT STD_LOGIC;
            motor_puerta_B  : OUT STD_LOGIC;
            motor_puerta_EN : OUT STD_LOGIC;
            disp_pers_dec   : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_pers_uni   : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_cabina     : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_piso1      : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_piso2      : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_piso3      : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_piso4      : OUT STD_LOGIC_VECTOR(6 downto 0);
            disp_piso5      : OUT STD_LOGIC_VECTOR(6 downto 0);
            buzzer          : OUT STD_LOGIC;
            luces_cabina    : OUT STD_LOGIC;
            clk_l           : OUT STD_LOGIC;
            led_puerta_abierta  : OUT STD_LOGIC;
            led_puerta_cerrada  : OUT STD_LOGIC;
            led_fallo_energia   : OUT STD_LOGIC;
            led_notificacion    : OUT STD_LOGIC;
            led_sobrecarga      : OUT STD_LOGIC;
            sim_fallo_energia   : IN  STD_LOGIC
        );
    END COMPONENT;

    -- Señales de entrada
    SIGNAL clk_50MHz      : STD_LOGIC := '0';
    SIGNAL reset          : STD_LOGIC := '1';
    SIGNAL boton_subir    : STD_LOGIC_VECTOR(3 downto 0) := (OTHERS => '0');
    SIGNAL boton_bajar    : STD_LOGIC_VECTOR(4 downto 1) := (OTHERS => '0');
    SIGNAL boton_cabina   : STD_LOGIC_VECTOR(4 downto 0) := (OTHERS => '0');
    SIGNAL boton_abrir    : STD_LOGIC := '0';
    SIGNAL boton_cerrar   : STD_LOGIC := '0';
    SIGNAL boton_notif    : STD_LOGIC := '0';
    SIGNAL sensor_entrada : STD_LOGIC := '0';
    SIGNAL sensor_salida  : STD_LOGIC := '0';
    SIGNAL piso_sensor    : STD_LOGIC_VECTOR(4 downto 0) := "00001"; -- Piso 1 inicial
    SIGNAL fin_puerta_abierta : STD_LOGIC := '0';
    SIGNAL fin_puerta_cerrada : STD_LOGIC := '0';
    SIGNAL sim_fallo_energia : STD_LOGIC := '0';
    
    -- Señales de salida
    SIGNAL motor_subir     : STD_LOGIC;
    SIGNAL motor_bajar     : STD_LOGIC;
    SIGNAL motor_puerta_A  : STD_LOGIC;
    SIGNAL motor_puerta_B  : STD_LOGIC;
    SIGNAL motor_puerta_EN : STD_LOGIC;
    SIGNAL disp_pers_dec   : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_pers_uni   : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_cabina     : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_piso1      : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_piso2      : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_piso3      : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_piso4      : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL disp_piso5      : STD_LOGIC_VECTOR(6 downto 0);
    SIGNAL buzzer          : STD_LOGIC;
    SIGNAL luces_cabina    : STD_LOGIC;
    SIGNAL clk_l           : STD_LOGIC;
    SIGNAL led_puerta_abierta  : STD_LOGIC;
    SIGNAL led_puerta_cerrada  : STD_LOGIC;
    SIGNAL led_fallo_energia   : STD_LOGIC;
    SIGNAL led_notificacion    : STD_LOGIC;
    SIGNAL led_sobrecarga      : STD_LOGIC;
    
    -- Periodo del reloj (50 MHz -> 20 ns)
    CONSTANT clk_period : TIME := 20 ns;
    
BEGIN
    -- Instanciación del DUT
    dut: Ascensor PORT MAP(
        clk_50MHz       => clk_50MHz,
        reset           => reset,
        boton_subir     => boton_subir,
        boton_bajar     => boton_bajar,
        boton_cabina    => boton_cabina,
        boton_abrir     => boton_abrir,
        boton_cerrar    => boton_cerrar,
        boton_notif     => boton_notif,
        sensor_entrada  => sensor_entrada,
        sensor_salida   => sensor_salida,
        piso_sensor     => piso_sensor,
        fin_puerta_abierta => fin_puerta_abierta,
        fin_puerta_cerrada => fin_puerta_cerrada,
        motor_subir     => motor_subir,
        motor_bajar     => motor_bajar,
        motor_puerta_A  => motor_puerta_A,
        motor_puerta_B  => motor_puerta_B,
        motor_puerta_EN => motor_puerta_EN,
        disp_pers_dec   => disp_pers_dec,
        disp_pers_uni   => disp_pers_uni,
        disp_cabina     => disp_cabina,
        disp_piso1      => disp_piso1,
        disp_piso2      => disp_piso2,
        disp_piso3      => disp_piso3,
        disp_piso4      => disp_piso4,
        disp_piso5      => disp_piso5,
        buzzer          => buzzer,
        luces_cabina    => luces_cabina,
        clk_l           => clk_l,
        led_puerta_abierta  => led_puerta_abierta,
        led_puerta_cerrada  => led_puerta_cerrada,
        led_fallo_energia   => led_fallo_energia,
        led_notificacion    => led_notificacion,
        led_sobrecarga      => led_sobrecarga,
        sim_fallo_energia   => sim_fallo_energia
    );

    -- Generación de reloj
    clk_50MHz <= NOT clk_50MHz AFTER clk_period/2;

    -- Proceso de estímulo
    stim_proc: PROCESS
    BEGIN
        -- Inicialización/reset
        reset <= '1';
        WAIT FOR 100 ns;
        reset <= '0';
        WAIT FOR clk_period*5;
        
        -- Secuencia de prueba:
        -- 1. Cierre de puerta inicial
        fin_puerta_cerrada <= '1';
        WAIT FOR clk_period*2;
        fin_puerta_cerrada <= '0';
        WAIT FOR clk_period*5;
        
        -- 2. Solicitar piso 3 desde cabina
        boton_cabina <= (2 => '1', OTHERS => '0'); -- Piso 3
        WAIT FOR clk_period*5;
        boton_cabina <= (OTHERS => '0');
        
        -- 3. Simular movimiento al piso 3
        WAIT FOR 500 ns;
        piso_sensor <= "00100"; -- Piso 3
        
        -- 4. Simular apertura de puerta
        WAIT FOR clk_period*10;
        fin_puerta_abierta <= '1';
        WAIT FOR clk_period*2;
        fin_puerta_abierta <= '0';
        
        -- 5. Solicitar cierre de puerta
        WAIT FOR clk_period*10;
        boton_cerrar <= '1';
        WAIT FOR clk_period*2;
        boton_cerrar <= '0';
        
        -- 6. Simular cierre de puerta
        WAIT FOR clk_period*10;
        fin_puerta_cerrada <= '1';
        WAIT FOR clk_period*2;
        fin_puerta_cerrada <= '0';
        
        -- 7. Finalizar simulación
        WAIT FOR 1 us;
        ASSERT FALSE REPORT "Simulación completada" SEVERITY NOTE;
        WAIT;
    END PROCESS;

END Behavioral;