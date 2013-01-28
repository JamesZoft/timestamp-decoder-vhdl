library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity fifo is

    generic
    (
        gate_delay: time     := 0 ns;
        ts_digits:  positive;
        size:       positive := 1
    );

    port
    (
        rst: in  std_logic                                  :=            'X';           -- reset
        clk: in  std_logic                                  :=            'X';           -- clock

        wi:  in  std_logic                                  :=            'X';           -- write in
        tsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);  -- timestamp in
        lbi: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- last received bit in
        tci: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- timestamp YYYY-MM-DD HH:MM:SS in
        idi: in  byte_vector(0 to 2)                        := (others => byte_unknown); -- ID in
        fi:  out std_logic                                  :=            '0';           -- buffer full

        wo:  out std_logic                                  :=            '0';           -- write out
        tso: out bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_zero);     -- timestamp out
        lbo: out bcd_digit_vector( 1 downto 0)              := (others => bcd_zero);     -- last received bit out
        tco: out bcd_digit_vector(13 downto 0)              := (others => bcd_zero);     -- timestamp YYYY-MM-DD HH:MM:SS out
        ido: out byte_vector(0 to 2)                        := (others => byte_unknown); -- ID out
        bo:  in  std_logic                                  :=            'X'            -- busy out
    );

end fifo;

architecture rtl of fifo is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
