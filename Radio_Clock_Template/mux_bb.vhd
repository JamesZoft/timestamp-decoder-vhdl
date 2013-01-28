library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity mux_bb is

    generic
    (
        gate_delay: time     := 0 ns;
        ts_digits:  positive
    );

    port
    (
        rst:  in  std_logic                                  :=            'X';           -- reset
        clk:  in  std_logic                                  :=            'X';           -- clock

        awi:  in  std_logic                                  :=            'X';           -- A write in
        atsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);  -- A timestamp in
        albi: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- A last received bit in
        atci: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- A timestamp YYYY-MM-DD HH:MM:SS in
        aidi: in  byte_vector(0 to 2)                        := (others => byte_unknown); -- A ID in
        afi:  out std_logic                                  :=            '0';           -- A buffer full

        bwi:  in  std_logic                                  :=            'X';           -- B write in
        btsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);  -- B timestamp in
        blbi: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- B last received bit in
        btci: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- B timestamp YYYY-MM-DD HH:MM:SS in
        bidi: in  byte_vector(0 to 2)                        := (others => byte_unknown); -- B ID in
        bfi:  out std_logic                                  :=            '0';           -- B buffer full

        wo:   out std_logic                                  :=            '0';           -- write out
        tso:  out bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_zero);     -- timestamp out
        lbo:  out bcd_digit_vector( 1 downto 0)              := (others => bcd_zero);     -- last received bit out
        tco:  out bcd_digit_vector(13 downto 0)              := (others => bcd_zero);     -- timestamp YYYY-MM-DD HH:MM:SS out
        ido:  out byte_vector(0 to 2)                        := (others => byte_unknown); -- ID out
        bo:   in  std_logic                                  :=            'X'            -- busy out
    );

end mux_bb;

architecture bb of mux_bb is

    component mux

    port
    (
        rst:  in  std_logic                                  :=            'X';           -- reset
        clk:  in  std_logic                                  :=            'X';           -- clock

        awi:  in  std_logic                                  :=            'X';           -- A write in
        atsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);  -- A timestamp in
        albi: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- A last received bit in
        atci: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- A timestamp YYYY-MM-DD HH:MM:SS in
        aidi: in  byte_vector(0 to 2)                        := (others => byte_unknown); -- A ID in
        afi:  out std_logic                                  :=            '0';           -- A buffer full

        bwi:  in  std_logic                                  :=            'X';           -- B write in
        btsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);  -- B timestamp in
        blbi: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- B last received bit in
        btci: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- B timestamp YYYY-MM-DD HH:MM:SS in
        bidi: in  byte_vector(0 to 2)                        := (others => byte_unknown); -- B ID in
        bfi:  out std_logic                                  :=            '0';           -- B buffer full

        wo:   out std_logic                                  :=            '0';           -- write out
        tso:  out bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_zero);     -- timestamp out
        lbo:  out bcd_digit_vector( 1 downto 0)              := (others => bcd_zero);     -- last received bit out
        tco:  out bcd_digit_vector(13 downto 0)              := (others => bcd_zero);     -- timestamp YYYY-MM-DD HH:MM:SS out
        ido:  out byte_vector(0 to 2)                        := (others => byte_unknown); -- ID out
        bo:   in  std_logic                                  :=            'X'            -- busy out
    );
    
    end component;
    
begin

    mux_inst: mux
    
    port map
    (
        rst  => rst,
        clk  => clk,

        awi  => awi,
        atsi => atsi,
        albi => albi,
        atci => atci,
        aidi => aidi,
        afi  => afi,

        bwi  => bwi,
        btsi => btsi,
        blbi => blbi,
        btci => btci,
        bidi => bidi,
        bfi  => bfi,

        wo   => wo,
        tso  => tso,
        lbo  => lbo,
        tco  => tco,
        ido  => ido,
        bo   => bo
    );

end bb;
