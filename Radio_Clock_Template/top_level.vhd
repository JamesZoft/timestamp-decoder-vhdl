library IEEE;

use IEEE.std_logic_1164.all;
use WORK.util.all;

entity top_level is

    port
    (
        clk:  in  std_logic;                    -- clock
        btnu: in  std_logic;                    -- button up
        btnd: in  std_logic;                    -- button down
        btnc: in  std_logic;                    -- button centre
        btnl: in  std_logic;                    -- button left
        btnr: in  std_logic;                    -- button right
        sw:   in  std_logic_vector(7 downto 0); -- switches
        an:   out std_logic_vector(3 downto 0); -- anodes   7 segment display
        ka:   out std_logic_vector(7 downto 0); -- kathodes 7 segment display
        ld:   out std_logic_vector(7 downto 0); -- leds
        rx:   in  std_logic;                    -- uart rx 
        tx:   out std_logic;                    -- uart tx
        msf:  in  std_logic;                    -- msf signal
        dcf:  in  std_logic                     -- dcf signal
   );

end top_level;

architecture behav of top_level is

    constant clk_freq:   positive  := 100000000; -- Hz
    constant clk_period: time      :=  1000 ms / clk_freq;
    constant debounce:   natural   := 80; -- us
    constant baud_rate:  positive  :=   57600; -- Baud
    constant bit_period: time      :=  1000 ms / baud_rate;
    constant ts_digits:  positive  := 5 + 8;
    constant signals:    positive  := 9;
    constant fifo_size:  positive  := 16;

    signal   rst:        std_logic                                  :=            '0';
    signal   ev:         std_logic_vector((signals - 1) downto 0)   := (others => '0');

    signal   up_t:       bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_zero); 

    signal   tr_d:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_e:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_r:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_f:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_w:       std_logic                                  :=            'X';

    constant msf_i:      byte_vector(0 to 2)                        := to_byte_vector("MSF");
    signal   msf_s:      std_logic                                  :=            'X';
    signal   msf_m:      std_logic                                  :=            'X';
    signal   msf_w:      std_logic                                  :=            'X';
    signal   msf_b:      bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    signal   msf_t:      bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);

    constant dcf_i:      byte_vector(0 to 2)                        := to_byte_vector("DCF");
    signal   dcf_s:      std_logic                                  :=            'X';
    signal   dcf_m:      std_logic                                  :=            'X';
    signal   dcf_w:      std_logic                                  :=            'X';
    signal   dcf_b:      bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    signal   dcf_t:      bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);

    signal   mx_a:       std_logic                                  :=            'X';
    signal   mx_b:       std_logic                                  :=            'X';
    signal   mx_w:       std_logic                                  :=            'X';
    signal   mx_ts:      bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_space);
    signal   mx_tc:      bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);
    signal   mx_lb:      bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    signal   mx_id:      byte_vector(0 to 2)                        := to_byte_vector("MSF");

    signal   fi_ts:      bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_space);
    signal   fi_x:       bcd_digit_vector(13 downto 0)              := (others => bcd_space);
    signal   fi_tc:      bcd_digit_vector(13 downto 0)              := (others => bcd_space);
    signal   fi_lb:      bcd_digit_vector( 1 downto 0)              := (others => bcd_space);
    signal   fi_id:      byte_vector(0 to 2)                        := (others => byte_space);
    signal   fi_f:       std_logic                                  :=            'X';
    signal   fi_w:       std_logic                                  :=            'X';

    signal   tx_b:       std_logic                                  :=            '0';
    signal   tx_w:       std_logic                                  :=            '0';
    signal   tx_d:       byte                                       :=            byte_null;

    signal   sp_b:       std_logic                                  :=            '0';
    signal   sp_d:       std_logic                                  :=            '0';

begin

    uptime_unit: entity WORK.bcd_counter
    generic map
    (
        leading_zero => false,
        digits       => ts_digits
    )
    port map
    (
        rst          => rst,
        clk          => clk,
        en           => '1',
        
        cnt          => up_t
    );

    trigger_unit: entity WORK.trigger
    generic map
    (
        clk_freq   => clk_freq,
        debounce   => 0,
        signals    => signals
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        di         => ev,

        do         => tr_d,
        eo         => tr_e,
        ro         => tr_r,
        fo         => tr_f,
        wo         => tr_w
    );

    msf_unit: entity WORK.msf_bb
    generic map
    (
        clk_freq   => clk_freq
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        ri         => tr_r(8),
        fi         => tr_f(8),
        
        so         => msf_s,
        mo         => msf_m,

        wo         => msf_w,
        bo         => msf_b,
        tso        => msf_t
    );

    dcf_unit: entity WORK.dcf_bb
    generic map
    (
        clk_freq   => clk_freq
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        ri         => tr_r(7),
        fi         => tr_f(7),
        
        so         => dcf_s,
        mo         => dcf_m,

        wo         => dcf_w,
        bo         => dcf_b,
        tso        => dcf_t
    );

    mux_uut: entity WORK.mux
    generic map
    (
        ts_digits  => ts_digits
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        awi        => msf_w,
        atsi       => up_t,
        atci       => msf_t,
        albi       => msf_b,
        aidi       => msf_i,
        afi        => mx_a,

        bwi        => dcf_w,
        btsi       => up_t,
        btci       => dcf_t,
        blbi       => dcf_b,
        bidi       => dcf_i,
        bfi        => mx_b,

        wo         => mx_w,
        tso        => mx_ts,
        tco        => mx_tc,
        lbo        => mx_lb,
        ido        => mx_id,
        bo         => fi_f
    );
    
    fifo_unit: entity WORK.fifo_bb
    generic map
    (
        ts_digits  => ts_digits,
        size       => fifo_size
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        wi         => mx_w,
        tsi        => mx_ts,
        tci        => mx_tc,
        lbi        => mx_lb,
        idi        => mx_id,
        fi         => fi_f,

        wo         => fi_w,
        tso        => fi_ts,
        tco        => fi_tc,
        lbo        => fi_lb,
        ido        => fi_id,
        bo         => tx_b
    );
    
    transmitter_unit: entity WORK.transmitter_bb
    generic map
    (
        ts_digits  => 14
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        wi         => fi_w,
        ii         => fi_id,
        ti         => fi_x,
        bti        => fi_lb,
        tsi        => fi_tc,
        bi         => tx_b,

        wo         => tx_w,
        do         => tx_d,
        bo         => sp_b
    );
    
    serial_port_unit: entity WORK.serial_port 
    generic map
    (
        clk_freq   => clk_freq,
        baud_rate  => baud_rate
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        wi         => tx_w,
        di         => tx_d,
        bi         => sp_b,

        do         => sp_d
    );

    fi_x  <= fi_ts(ts_digits - 1 downto 9) & space_to_zero(fi_ts(8 downto 8) & bcd_dot & fi_ts(7 downto 0));

    rst   <= sw(0);
    ev    <= (msf and sw(6), dcf and sw(7), rx, btnr, btnl, btnc, btnd, btnu, '0');
    an    <= (others => '1');
    ka    <= (others => '0');

    ld(0) <= rst;
    ld(1) <= sw(1) or sw(2) or sw(3) or sw(4) or sw(5);
    ld(2) <= dcf_s;
    ld(3) <= dcf_m;
    ld(4) <= msf_s;
    ld(5) <= msf_m;
    ld(6) <= msf;
    ld(7) <= dcf;
    
    tx    <= sp_d;

end behav;
