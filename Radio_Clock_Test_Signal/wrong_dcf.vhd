library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf is

    generic
    (
        clk_freq:    positive;                                               -- clock frequency in Hz
        gate_delay:  time                          :=             0 ns;       -- gate delay
        signals:      positive                     :=             1    -- number of signals
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
        bo:      out bcd_digit_vector( 1 downto 0) := (others => bcd_zero); -- last received bit
        tso:     out bcd_digit_vector(13 downto 0) := (others => bcd_zero)  -- timestamp YYYY-MM-DD HH:MM:SS
    );

end dcf;

architecture rtl of dcf is

    constant bit_0:       		natural                              := (clk_freq / 1000) * 100;
    constant bit_1:       		natural                              := (clk_freq / 1000) * 200;
    constant max_counter:			natural                              := (clk_freq / 1000) * 1500;
    constant tolerance :  		natural															 := (clk_freq / 1000) * 20;
    constant spike_tolerance: natural															 := bit_0 - tolerance;
    
    signal  counter: unsigned(max(1, n_bits(max_counter) - 1) downto 0) 		 := (others => '0');
    signal  next_counter: unsigned(max(1, n_bits(max_counter) - 1) downto 0) := (others => '0');
    
    type states is (neutral, rising, hi, fall);
    signal current_state:		states 																 := neutral;
    signal next_state:			states 																 := neutral;
    
    signal valid_bits: integer																		 := 0;
    
    signal   bit_storage:     unsigned(0 to 58)   				 := (others => '0');
    

begin
	
			process (rst,clk, counter) --detect bit
			begin		
			
				if (rst = '1') then -- If reset
		
					counter <= (others => '0');
					current_state <= neutral;
								
				elsif clk'event and (clk = '1') then	--On clock ri
				
					current_state <= next_state;
					counter <= next_counter;
						
				end if;
			
			end process;
			
			process(current_state, counter, ri, fi)
			begin	
			
				wo <= '0';
				mo <= '0';
				so <= '0';
				bo <= (others => bcd_zero);
				next_counter <= counter + 1;
								
				case current_state is
					
						when neutral =>
							
							if (counter > (clk_freq) and (counter < (max_counter))) then
							
								bit_storage <= (others => '0');
								valid_bits <= 0;
								
								if(valid_bits = 59) then
									
									mo <= '1';
									so <= '1';
									
								end if;
							
							end if;

							if (ri = '1') then --if there's a inc. signal
							
								next_state <= rising;
								
								next_counter <= (others => '0');
					
							end if;
							
						when rising =>
							
							if (counter > tolerance) then
														
								so <= '1';
								
								next_state <= hi;														
							
							end if;
						
						when hi =>
					
							if (fi = '1') and (counter > spike_tolerance) then --if it's got to the end of the signal, make sure it isnt a spike
							
								--next_counter <= (others => '0');
								
								--wo <= '1';
						
								if (counter <= (bit_1 + tolerance) and counter >= (bit_1 - tolerance)) then --if it's bit 1
					
			-- 		    		bo <= (bcd_zero & bcd_one);
			 		    		valid_bits <= valid_bits + 1;
			-- 		    		bit_storage(valid_bits) <= '1';
			 --		    		wo <= '1';
			 		    		
								elsif (counter <= (bit_0 + tolerance) and counter >= (bit_0 - tolerance)) then -- if it's bit 0
				
			--	 					bo <= (bcd_zero & bcd_zero);
									valid_bits <= valid_bits + 1;
			--						bit_storage(valid_bits) <= '0';
			--						wo <= '1';
						
								end if;
																
								next_state <= fall;
								
							end if;
								
						when fall =>
						
							next_counter <= (others => '0');
							next_state <= neutral;

						end case;
				
			end process;
			
--			process(valid_bits)
--			begin
			
	--			if (valid_bits = 58) then
				
	--				tso(11) <= bit_storage(21 to 24);
	--				tso(10) <= (bcd_zero & bit_storage(25 to 27));
	--				tso(9)  <= bit_storage(29 to 32);
	--				tso(8)  <= (bcd_zero & bcd_zero & bit_storage(33 to 34));
	--				tso(7)	<= bit_storage(36 to 39);
	--				tso(6)	<= (bcd_zero & bcd_zero &bit_storage(40 to 41));
	--				tso(5)	<= bit_storage(45 to 48);
	--				tso(4)	<= (bcd_zero & bcd_zero & bcd_zero & bit_storage(49 to 49));
	--				tso(3)	<= bit_storage(50 to 53);
	--				tso(2)	<= bit_storage(54 to 57);
	--				tso(1)	<= bcd_zero;
	--				tso(0)	<= bcd_two;
	--			
	--			end if;
			
	--		end process;
		
end rtl;
