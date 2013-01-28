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
        rst:     			in  std_logic                     :=            'X';        -- reset
        clk:     			in  std_logic                     :=            'X';        -- clock
        
        ri:      			in  std_logic                     :=            'X';        -- rising edge in
        fi:      			in  std_logic                     :=            'X';        -- falling edge in

        so:      			out std_logic                     :=            '0';        -- new second out
        mo:      			out std_logic                     :=            '0';        -- new minute out
        wo:      			out std_logic                     :=            '0';        -- write out
        bo:      			out bcd_digit_vector( 1 downto 0) := (others => bcd_zero); -- last received bit
        tso:     			out bcd_digit_vector(13 downto 0) := (others => bcd_zero)  -- timestamp YYYY-MM-DD HH:MM:SS

    );

end dcf;

architecture rtl of dcf is


	--Function that takes a range of unsigneds, xors them together then returns the
	--result as std_logic. This is for detirmining if the parity checks out - i.e. I xor all the bits 
	--over which the parity bit is assigned to, plus the parity bit, and if the result is 0,
	--the parity is correct
		function xor_bits(slv: unsigned) return std_logic is 
        variable l: std_logic := '0';
    begin
    
        for i in slv'range loop
            l := l xor slv(i);
        end loop;
        
        return l;

    end function xor_bits;

    constant bit_0:       		natural                              := (clk_freq / 1000) * 100; --Pulse width for a 0 bit on the DCF
    constant bit_1:       		natural                              := (clk_freq / 1000) * 200; --Pulse width for a 1 bit on the DCF
    constant max_counter:			natural                              := (clk_freq / 1000) * 1500; --Maximum value for my counter
    constant tolerance :  		natural															 := (clk_freq / 1000) * 20; --Tolerance given to pulse width
    constant spike_tolerance: natural															 := bit_0 - tolerance; 			--Utility field, used to measure if a 
    																																													--pulse is an actual pulse or a spike
    
    --Counter for detecting pulse widths
    signal  counter: unsigned(max(1, n_bits(max_counter) - 1) downto 0) 		 := (others => '0'); 
    --next_counter is needed so that counter can be clocked 
    signal  next_counter: unsigned(max(1, n_bits(max_counter) - 1) downto 0) := (others => '0');
    
    --Collection of states for FSM
    type states is (neutral, rising, hi, fall);
    
    --Two signals for state so that it can be clocked
    signal current_state:		states 																 := neutral;
    signal next_state:			states 																 := neutral;
    
    --Signal used to detect how many valid bits I have received, with a next_signal so it can be clocked
    signal valid_bits: 			integer																		 := 0;
    signal next_valid_bits: integer																		 := 0;
    
    --Signal used to store the bits whilst I'm receiving them, with a next_signal so it can be clocked
    signal   bit_storage:     				unsigned(58 downto 0)   				 := (others => '0');
    signal   next_bit_storage:     		unsigned(58 downto 0)   				 := (others => '0');
    
    --Signal used as a flag to detect if a minute has been detected, with a next_signal so it can be clocked
    signal minute_detected: 			boolean												 := false;
    signal next_minute_detected:	boolean												 := false;
    
    --current_tso is wired directly to tso below, next_tso needed so it can be clocked
    signal next_tso: 								bcd_digit_vector(11 downto 0) 	 := (others => bcd_zero);  -- timestamp YYYY-MM-DD HH:MM:SS
    signal current_tso: 						bcd_digit_vector(13 downto 0) 	 := (others => bcd_minus);  -- timestamp YYYY-MM-DD HH:MM:SS
    
    --These signals are for storing the output of the xor'ing method above and are checked when tso is being assigned to to make sure
    --that the information I have received is correct (according to the parity, of course it could still be wrong if two bits were the
    --wrong value
    signal parity_bit_minute: std_logic																:= '0';
    signal parity_bit_hour: 	std_logic																:= '0';
    signal parity_bit_date: 	std_logic																:= '0';
    
    --next_signals for the above signals so they can be clocked
    signal next_parity_bit_minute:  std_logic																:= '0';
    signal next_parity_bit_hour: 		std_logic																:= '0';
    signal next_parity_bit_date: 		std_logic																:= '0';
    
    --Signal so that I can reset the bcd counter I have included in this design, with a next_signal so it can be clocked
    signal bcd_rst: std_logic := '0';
    signal next_bcd_rst: std_logic := '0';
    
    --An internal so signal so that the bcd counter can use it as its enable pin.
    signal int_so: std_logic := '0';
    
		signal next_bo: bcd_digit_vector( 1 downto 0) := (others => bcd_zero); -- last received bit
		signal current_bo: bcd_digit_vector( 1 downto 0) := (others => bcd_zero); -- last received bit
    
    
    

begin

	--Including the bcd counter in this design. Its output value is assigned to current_tso's 1 and 0 values which are the tens and units
	--of the seconds part of tso, respectively. Rst is wired to bcd_rst, which is above, with the trigger being my internal so signal
	dcf_unit: entity WORK.bcd_counter
  generic map
  (
        leading_zero => true,
        digits => 2
  )
  port map
  (
  	rst => bcd_rst,
    clk => clk,
    en => int_so,
    
    cnt => current_tso(1 downto 0)
  );
  
   

	tso <= current_tso;
	so <= int_so;
	bo <= current_bo;

	process (rst,clk) --This process contains all of the reset values and clocks all signals needing to be clocked.
	begin		
	
		if (rst = '1') then -- If reset

			counter <= (others => '0');
			current_state <= neutral;
			valid_bits <= 0;
			minute_detected <= false;
			current_tso(13 downto 2) <= (others => bcd_minus);
			bit_storage <= (others => '0');
			parity_bit_minute <= '0';
			parity_bit_hour <= '0';
			parity_bit_date <= '0';
			bcd_rst <= '0';
			current_bo <= (others => bcd_zero);
	
		elsif clk'event and (clk = '1') then	--On clock ri
		
			current_state <= next_state;
			counter <= next_counter;
			valid_bits <= next_valid_bits;
			minute_detected <= next_minute_detected;
			current_tso(13 downto 2) <= next_tso;
			bit_storage <= next_bit_storage;	
			parity_bit_minute <= next_parity_bit_minute;		
			parity_bit_hour <= next_parity_bit_hour;
			parity_bit_date <= next_parity_bit_date;
			bcd_rst <= next_bcd_rst;
			current_bo <= next_bo;
				
		end if;
	
	end process;
	
	
	--This process contains my FSM, the minute detection, second detection and bit value detection & storage
	process(current_state, counter, ri, fi, clk, minute_detected, valid_bits, bit_storage, bcd_rst, current_bo)
	begin	
	
		mo <= '0';
		wo <= '0';
		int_so <= '0';
		next_bo <= current_bo;
		next_counter <= counter + 1;
		next_minute_detected <= minute_detected;
		next_bit_storage <= bit_storage;
		next_valid_bits <= valid_bits;
		next_state <= current_state;
		next_bcd_rst <= '0';
		
						
		case current_state is
			
				when neutral =>
					
					 --Probably a minute, but we don't output mo immediately as it could just be a missed second
					if (counter > (clk_freq) and (counter < (max_counter))) then
					
						next_bit_storage <= (others => '0');
						next_valid_bits <= 0;
						
						
						if(valid_bits = 59) then --We've had 59 valid seconds, so this must be a new minute
							
							next_minute_detected <= true;
							int_so <= '1';
							next_bit_storage <= (others => '0');
							
						end if; 
					
					end if;

					if (ri = '1') then --if there's a inc. signal
					
						next_state <= rising;
						
						next_counter <= (others => '0');
			
					end if;
					
				when rising =>
					
					if (counter > tolerance) then --Second detected
												
						int_so <= '1';
						wo <= '1';

						
						next_state <= hi;
						
						--Output mo on the first new ri after it was detected so that mo doesn't go high in the middle of the long gap
						if (minute_detected = true) then
							
							mo <= '1';
							next_minute_detected <= false;
							
							
						end if;
						
						--Reset the bcd counter when the new minute starts 
						if(valid_bits = 0) then
						
							next_bcd_rst <= '1';
						
						end if;
					
					elsif (fi = '1') then
						
						next_state <= neutral;									
					
					end if;
				
				when hi =>
			
					if (fi = '1') and (counter > spike_tolerance) then --if it's got to the end of the signal, make sure it isnt a spike
				
						if (counter <= (bit_1 + tolerance) and counter >= (bit_1 - tolerance)) then --if it's bit 1
			
	 		    		next_bo <= (bcd_space & bcd_one);
	 		    		next_valid_bits <= valid_bits + 1;
	 		    		next_bit_storage(valid_bits) <= '1';
	 		    		--wo <= '1';
	 		    		
						elsif (counter <= (bit_0 + tolerance) and counter >= (bit_0 - tolerance)) then -- if it's bit 0
		
		 					next_bo <= (bcd_space & bcd_zero);
							next_valid_bits <= valid_bits + 1;
							next_bit_storage(valid_bits) <= '0';
							--wo <= '1';
				
						end if;
														
						next_state <= fall;
						
					end if;
						
				when fall =>
				
					next_counter <= (others => '0'); --Reset the counter
					next_state <= neutral;

				end case;
		
	end process;
	
	--This process checks whether all of the parity bits check out, then assigns the values from the minute just passed into next_tso,
	--which will filter down into tso
	process(valid_bits, bit_storage, current_tso, parity_bit_minute, parity_bit_hour, parity_bit_date)
	begin
		
		next_tso <= current_tso(13 downto 2);

		if (valid_bits = 59) and (parity_bit_minute = '0') and (parity_bit_hour = '0') and (parity_bit_date = '0') then
			
				next_tso(0) <= bit_storage(24 downto 21);
				next_tso(1) <= ('0' & bit_storage(27 downto 25));
			
				next_tso(2)  <= bit_storage(32 downto 29);
				next_tso(3)  <= ("00" & bit_storage(34 downto 33));
			
				next_tso(4)	<= bit_storage(39 downto 36);
				next_tso(5)	<= ("00" & bit_storage(41 downto 40));
				next_tso(6)	<= bit_storage(48 downto 45);
				next_tso(7)	<= ("000" & bit_storage(49 downto 49));
				next_tso(8)	<= bit_storage(53 downto 50);
				next_tso(9)	<= bit_storage(57 downto 54);
			
			--dcf doesn't give the first two year digits, so these have to be hard-coded
				next_tso(10)	<= bcd_zero;
				next_tso(11)	<= bcd_two;
	
		end if;

	end process;
	
	--This process assigns the value of the xor_bits method above to the signals that will be used to check the parity in the above process
	process(bit_storage, parity_bit_minute, parity_bit_hour, parity_bit_date)
	begin
	
		next_parity_bit_minute <= parity_bit_minute;
		next_parity_bit_hour   <= parity_bit_hour;
		next_parity_bit_date   <= parity_bit_date;
	
		next_parity_bit_minute <= xor_bits(bit_storage(28 downto 21));
		
		next_parity_bit_hour 	 <= xor_bits(bit_storage(35 downto 29));
	
		next_parity_bit_date 	 <= xor_bits(bit_storage(58 downto 36));
		
	end process;
	

		
end rtl;
