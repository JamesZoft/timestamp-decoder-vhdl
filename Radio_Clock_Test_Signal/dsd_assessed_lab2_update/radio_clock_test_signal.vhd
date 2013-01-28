library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity radio_clock_test_signal is
end radio_clock_test_signal;



architecture behav of radio_clock_test_signal is

    signal   clk:      std_logic                                  :=            '0';
    constant signals:    positive  := 9;

    signal   full:       std_logic := 'X';

    signal   btnu:       std_logic := 'X';
    signal   btnd:       std_logic := 'X';
    signal   btnc:       std_logic := 'X';
    signal   btnl:       std_logic := 'X';
    signal   btnr:       std_logic := 'X';

    signal   rx:         std_logic := 'X';

    signal   dcf:        std_logic := 'X';
    signal   msf:        std_logic := 'X';
    signal   dcf_s:      std_logic                                  :=            'X';
    signal   dcf_m:      std_logic                                  :=            'X';
    signal   dcf_w:      std_logic                                  :=            'X';
    signal   dcf_b:      bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    signal   dcf_t:      bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);

    signal   tr_d:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_e:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_r:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_f:       std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_w:       std_logic                                  :=            'X';

    signal   rst:        std_logic                                  :=            '0';

    constant debounce:   natural   := 80; -- us
    signal   ev:         std_logic_vector((signals - 1) downto 0)   := (others => '0');
    constant clk_freq:   positive   := 10000; -- Hz
    constant baud_rate:  positive   := 57600; -- Baud
    constant bit_period: time       := 1000 ms / baud_rate;
    constant clk_period: time       := 1000 ms / clk_freq;
    constant rst_period: time       := 5 * bit_period;
    signal   end_flag: std_logic                                  :=            '0';

begin

		dcf_unit: entity WORK.dcf
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
    
    process
    begin
        rst <= '1';
        wait for rst_period;
        rst <= '0';
        wait;
    end process;

    process
    begin
    
        while end_flag = '0' loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        
        wait;
    end process;

    process
        file     data:      text;
        variable data_line: line;

        variable full_var:  std_logic;

        variable btnu_var:  std_logic;
        variable btnd_var:  std_logic;
        variable btnc_var:  std_logic;
        variable btnl_var:  std_logic;
        variable btnr_var:  std_logic;

        variable rx_var:    std_logic;

        variable dcf_var:   std_logic;
        variable msf_var:   std_logic;
        variable t_var:     time;
        variable t_real: 		time;
    begin
        file_open(data, "trace.cap", read_mode);
        
        while not endfile(data) loop
            readline(data, data_line);

            read(data_line, dcf_var);
            read(data_line, msf_var);

            read(data_line, rx_var);

            read(data_line, btnr_var);
            read(data_line, btnl_var);
            read(data_line, btnc_var);
            read(data_line, btnd_var);
            read(data_line, btnu_var);

            read(data_line, full_var);

            read(data_line, t_var);
            t_real := t_var - 0.0  ms; --64936.34234
            if t_real > now then
                wait for t_real - now;
            end if;

            full   <= full_var;
            btnu   <= btnu_var;
            btnd   <= btnd_var;
            btnc   <= btnc_var;
            btnl   <= btnl_var;
            btnr   <= btnr_var;
            rx     <= rx_var;
            dcf    <= dcf_var;
            msf    <= msf_var;
        end loop;
        
        file_close(data);
        end_flag <= '1';
        assert false report "end of test" severity note;
        wait;
    end process;
    
    ev(7) <= dcf;
    
end behav;
