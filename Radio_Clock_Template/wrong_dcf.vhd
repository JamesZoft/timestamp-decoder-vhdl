library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf is

    generic
    (
        clk_freq:    positive;                                               -- clock frequency in Hz
        gate_delay:  time                          :=             0 ns       -- gate delay
    );

    port
    (
        rst:     in  std_logic                     :=            'X';        -- reset
        clk:     in  std_logic                     :=            'X';        -- clock
        
        ri:      in  std_logic                     :=            'X';        -- rising edge in
        fi:      in  std_logic                     :=            'X';        -- falling edge in

        so:      out std_logic                     :=            '0';        -- new second out
        mo:      out std_logic                     :=            '0';        -- new minute out
        wo:      out std_logic                     :=            '0';        -- write out
        bo:      out bcd_digit_vector( 1 downto 0) := (others => bcd_minus); -- last received bit
        tso:     out bcd_digit_vector(13 downto 0) := (others => bcd_minus)  -- timestamp YYYY-MM-DD HH:MM:SS
    );

end dcf;

architecture rtl of dcf is

  -- Your declarations go here --

begin

  
  			  				
  	
end rtl;
