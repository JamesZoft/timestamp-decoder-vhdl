library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf is

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
        bo:      out bcd_digit_vector( 1 downto 0) := (others => bcd_minus); -- last received bit
        tso:     out bcd_digit_vector(13 downto 0) := (others => bcd_minus)  -- timestamp YYYY-MM-DD HH:MM:SS
    );

end msf;

architecture rtl of msf is



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

		--Pulse width for midpoint in between bit0 for a and bit1 for b
    constant pulse_mid:       natural                              := (clk_freq / 1000) * 80; 
    constant mid_tolerance :  natural															 := (clk_freq / 1000) * 7; --Tolerance given to pulse width
    constant pulse_100:       natural                              := (clk_freq / 1000) * 100; --Pulse width for a 0 bit on the DCF
    constant pulse_200:       natural                              := (clk_freq / 1000) * 200; --Pulse width for a 1 bit on the DCF
    constant pulse_300:       natural                              := (clk_freq / 1000) * 300; --Pulse width for minute marker on MSF
    constant pulse_500:       natural                              := (clk_freq / 1000) * 500; --Pulse width for minute marker on MSF
		constant max_counter:			natural                              := (clk_freq / 1000) * 1500; --Maximum value for my counter
    constant tolerance :  		natural															 := (clk_freq / 1000) * 20; --Tolerance given to pulse width
    constant spike_tolerance: natural															 := pulse_100 - tolerance; 			--Utility field, used to measure if a 
    																																													--pulse is an actual pulse or a spike
    
    --Counter for detecting pulse widths
    signal  counter: unsigned(max(1, n_bits(max_counter) - 1) downto 0) 		 := (others => '0'); 
    --next_counter is needed so that counter can be clocked 
    signal  next_counter: unsigned(max(1, n_bits(max_counter) - 1) downto 0) := (others => '0');
    
    --Collection of states for FSM
    type states is (neutral, rising, hi, bit0, bit1, fall);
    
    --Two signals for state so that it can be clocked
    signal current_state:		states 																 := neutral;
    signal next_state:			states 																 := neutral;
    
    --Signal used to detect how many valid bits I have received, with a next_signal so it can be clocked
    signal valid_bits: 			integer																		 := 1;
    signal next_valid_bits: integer																		 := 1;
    
    --Signal used to store the a bits whilst I'm receiving them, with a next_signal so it can be clocked
    signal   bit_storage_a:     				unsigned(1 to 60)   				 := (others => '0');
    signal   next_bit_storage_a:     		unsigned(1 to 60)   				 := (others => '0');
    
    
    --Signal used to store the b bits whilst I'm receiving them, with a next_signal so it can be clocked
    signal   bit_storage_b:     				unsigned(1 to 60)   				 := (others => '0');
    signal   next_bit_storage_b:     		unsigned(1 to 60)   				 := (others => '0');
    
    --Signal used as a flag to detect if a minute has been detected, with a next_signal so it can be clocked
    signal minute_detected: 			boolean												 := false;
    signal next_minute_detected:	boolean												 := false;
    
    --current_tso is wired directly to tso below, next_tso needed so it can be clocked
    signal next_tso: 								bcd_digit_vector(11 downto 0) 	 := (others => bcd_zero);  -- timestamp YYYY-MM-DD HH:MM:SS
    signal current_tso: 						bcd_digit_vector(13 downto 0) 	 := (others => bcd_minus);  -- timestamp YYYY-MM-DD HH:MM:SS
    
    --These signals are for storing the output of the xor'ing method above and are checked when tso is being assigned to to make sure
    --that the information I have received is correct (according to the parity, of course it could still be wrong if two bits were the
    --wrong value
  	signal parity_bit_time: std_logic			:= '0';
		signal parity_bit_day:  std_logic			:= '0';
		signal parity_bit_dow:  std_logic			:= '0';
		signal parity_bit_year: std_logic			:= '0';
		
    --next_signals for the above signals so they can be clocked
  	signal next_parity_bit_time: std_logic			:= '0';
		signal next_parity_bit_day:  std_logic			:= '0';
		signal next_parity_bit_dow:  std_logic			:= '0';
		signal next_parity_bit_year: std_logic			:= '0';
    
    --Signal so that I can reset the bcd counter I have included in this design, with a next_signal so it can be clocked
    signal bcd_rst: std_logic := '0';
    signal next_bcd_rst: std_logic := '0';
    
    --An internal so signal so that the bcd counter can use it as its enable pin.
    signal int_so: std_logic := '0';
    
    --Internal mo signal
    signal int_mo: std_logic := '0';
    
		signal next_bo: bcd_digit_vector( 1 downto 0)			:= (others => bcd_zero); -- last received bit
		signal current_bo: bcd_digit_vector( 1 downto 0)	:= (others => bcd_zero); -- last received bit

	
begin

	--Including the bcd counter in this design. Its output value is assigned to current_tso's 1 and 0 values which are the tens and units
	--of the seconds part of tso, respectively. Rst is wired to bcd_rst, which is above, with the trigger being my internal so signal
	msf_unit: entity WORK.bcd_counter
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
	mo <= int_mo;
	bo <= current_bo;

	process (rst,clk) --This process contains all of the reset values and clocks all signals needing to be clocked.
	begin		
	
		if (rst = '1') then -- If reset

			counter <= (others => '0');
			current_state <= neutral;
			valid_bits <= 1;
			minute_detected <= false;
			current_tso(13 downto 2) <= (others => bcd_minus);
			bit_storage_a <= (others => '0');
			bit_storage_b <= (others => '0');
			parity_bit_time	<= '0';		
			parity_bit_day	<= '0';
			parity_bit_dow	<= '0';
			parity_bit_year <= '0';
			bcd_rst <= '0';
			current_bo <= (others => bcd_zero);
	
		elsif clk'event and (clk = '1') then	--On clock ri
		
			current_state <= next_state;
			counter <= next_counter;
			valid_bits <= next_valid_bits;
			minute_detected <= next_minute_detected;
			current_tso(13 downto 2) <= next_tso;
			bit_storage_a <= next_bit_storage_a;	
			bit_storage_b <= next_bit_storage_b;	
			parity_bit_time <= next_parity_bit_time;		
			parity_bit_day <= next_parity_bit_day;
			parity_bit_dow <= next_parity_bit_dow;
			parity_bit_year <= next_parity_bit_year;
			bcd_rst <= next_bcd_rst;
			current_bo <= next_bo;
				
		end if;
	
	end process;
	
	
	process(int_so)
	begin
	
		wo <= '0';
		
		if (int_so = '1') then
			
			wo <= '1';
		
		end if;
	
	end process;
	
	--This process contains my FSM, the minute detection, second detection and bit value detection & storage
	process(current_state, counter, ri, fi, clk, minute_detected, valid_bits, bit_storage_a, bit_storage_b, bcd_rst, current_bo)
	begin	
	
		int_mo <= '0';

		int_so <= '0';
		next_bo <= current_bo;
		next_counter <= counter + 1;
		next_minute_detected <= minute_detected;
		next_bit_storage_a <= bit_storage_a;
		next_bit_storage_b <= bit_storage_b;
		next_valid_bits <= valid_bits;
		next_state <= current_state;
		next_bcd_rst <= '0';
		
						
		case current_state is
			
				when neutral =>

					if (ri = '1') then --if there's a inc. signal
					
						next_state <= rising;
						
						next_counter <= (others => '0');
			
					end if;
					
				when rising =>
				
					if (valid_bits = 60) then
						
						next_minute_detected <= true;
						
					end if;
					
					if (counter > tolerance) then --Second detected
												
						int_so <= '1';
						
						next_state <= hi;
						
						--Output mo on the first new ri after it was detected so that mo doesn't go high in the middle of the long gap
						if (minute_detected = true) then
							
							int_mo <= '1';
							next_minute_detected <= false;
							
						end if;
					
					elsif (fi = '1') then
						
						next_state <= neutral;									
					
					end if;
				
				when hi =>
				
					if (fi = '1') and (counter > spike_tolerance) then --if it's got to the end of the signal, make sure it isnt a spike
					
						
						if (counter < pulse_500 + tolerance) and (counter > pulse_500 - tolerance) then
						
							next_bcd_rst <= '1';
							next_valid_bits <= 1;
							next_bit_storage_a <= (others => '0');
							next_bit_storage_b <= (others => '0');
							next_state <= fall;
						
						else
						
							next_valid_bits <= valid_bits + 1;

							if (counter < pulse_100 + tolerance) and (counter > pulse_100 - tolerance) then
						
								next_bit_storage_a(valid_bits) <= '0';
							
							elsif (counter < pulse_200 + tolerance) and (counter > pulse_200 - tolerance) then
						
								next_bit_storage_a(valid_bits) <= '1';
								next_bit_storage_b(valid_bits) <= '0';
								next_state <= fall;
							
							elsif (counter < pulse_300 + tolerance) and (counter > pulse_300 - tolerance) then
						
								next_bit_storage_a(valid_bits) <= '1';
								next_bit_storage_b(valid_bits) <= '1';
								next_state <= fall;
							
							elsif (counter < pulse_500 + tolerance) and (counter > pulse_500 - tolerance) then
						
								next_valid_bits <= 1;
								next_bit_storage_a <= (others => '0');
								next_bit_storage_b <= (others => '0');
								next_state <= fall;
								
							end if;
						
						end if;
						
						next_state <= bit0;
						next_counter <= (others => '0');
					
					end if;
			  		
			  when bit0 =>
			  
			  	if (counter > pulse_mid + tolerance) then
			  	
			  		next_bit_storage_b(valid_bits) <= '0';
			  		next_state <= fall;
			  		
			  	else
			  	
			  		next_state <= bit0;
			  		
			  	end if;
			  
			  	--reset the counter so I can measure the length of the b bit pulse			  		
			  	if (ri = '1') then
			  	
			  		next_state <= bit1;
			  		next_counter <= (others => '0');
			  		
			  	end if;
			  	
			  when bit1 =>
			  
					if (fi = '1') and (counter > spike_tolerance) then --if it's got to the end of the signal, make sure it isnt a spike
						
						next_state <= fall;
						
						if (counter < pulse_100 + tolerance) and (counter > pulse_100 - tolerance) then
					
							next_bit_storage_b(valid_bits) <= '1';
							next_counter <= (others => '0');
						
						end if;
					
					end if;
						
				when fall =>
				
					next_counter <= (others => '0'); --Reset the counter
					next_state <= neutral;

				end case;
		
	end process;
	
	--This process checks whether all of the parity bits check out, then assigns the values from the minute just passed into next_tso,
	--which will filter down into tso
	process(valid_bits, bit_storage_a, current_tso, parity_bit_time, parity_bit_dow, parity_bit_day, parity_bit_year, int_mo)
	begin
		
		next_tso <= current_tso(13 downto 2);

		if (parity_bit_time = '1') and (parity_bit_day = '1') and (parity_bit_dow = '1') and (parity_bit_year = '1') and (int_mo = '1') then
			next_tso(0) <= bit_storage_a(48 to 51); --mi
			next_tso(1) <= ('0' & bit_storage_a(45 to 47)); --mi
	
			next_tso(2)  <= bit_storage_a(41 to 44); --h
			next_tso(3)  <= ("00" & bit_storage_a(39 to 40)); --h
	
			next_tso(4)	<= bit_storage_a(32 to 35); --d
			next_tso(5)	<= ("00" & bit_storage_a(30 to 31)); --d
			next_tso(6)	<= bit_storage_a(26 to 29); --mo
			next_tso(7)	<= ("000" & bit_storage_a(25 to 25)); --mo
			next_tso(8)	<= bit_storage_a(21 to 24); --y
			next_tso(9)	<= bit_storage_a(17 to 20); --y
	
		--dcf doesn't give the first two year digits, so these have to be hard-coded
			next_tso(10)	<= bcd_zero;
			next_tso(11)	<= bcd_two;
			
		end if;

	end process;
	
	--This process assigns the value of the xor_bits method above to the signals that will be used to check the parity in the above process
	process(bit_storage_a, bit_storage_b)
	begin
	
		next_parity_bit_year		<= xor_bits(bit_storage_a(17 to 24) & bit_storage_b(54));
		
		next_parity_bit_day			<= xor_bits(bit_storage_a(25 to 35) & bit_storage_b(55));
		
		next_parity_bit_dow			<= xor_bits(bit_storage_a(36 to 38) & bit_storage_b(56));
	
		next_parity_bit_time		<= xor_bits(bit_storage_a(39 to 51) & bit_storage_b(57));
		
	end process;
end rtl;
