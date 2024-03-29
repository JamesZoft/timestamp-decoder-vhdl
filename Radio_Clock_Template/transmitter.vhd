library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity transmitter is

    generic
    (
        gate_delay: time     := 0 ns;
        ts_digits:  positive := 14
    );

    port
    (
        rst: in  std_logic                                  :=            'X';           -- reset
        clk: in  std_logic                                  :=            'X';           -- clock

        wi:  in  std_logic                                  :=            'X';           -- write in
        ii:  in  byte_vector(0 to 2)                        := (others => byte_unknown); -- ID in
        ti:  in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- timestamp in
        bti: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- last received bit(s)
        tsi: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- timestamp YYYY-MM-DD HH:MM:SS
        bi:  out std_logic                                  :=            '0';           -- busy in

        wo:  out std_logic                                  :=            '0';           -- write out
        do:  out byte                                       :=            byte_null;     -- data out
        bo:  in  std_logic                                  :=            'X'            -- busy out
    );

end transmitter;

architecture rtl of transmitter is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
