library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity mux is

    generic
    (
        gate_delay: time     := 0 ns;
        ts_digits:  positive
    );

    port
    (
        rst:  in  std_logic                                  :=            '0';           -- reset
        clk:  in  std_logic                                  :=            '0';           -- clock

				-- a is msf
        awi:  in  std_logic                                  :=            '0';           -- A write in
        atsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);  -- A timestamp in
        albi: in  bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);  -- A last received bit in
        atci: in  bcd_digit_vector(13 downto 0)              := (others => bcd_unknown);  -- A timestamp YYYY-MM-DD HH:MM:SS in
        aidi: in  byte_vector(0 to 2)                        := (others => byte_unknown); -- A ID in
        afi:  out std_logic                                  :=            '0';           -- A buffer full

				-- b is dcf
        bwi:  in  std_logic                                  :=            '0';           -- B write in
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
        bo:   in  std_logic                                  :=            '0'            -- busy out
    );

end mux;

architecture rtl of mux is

	 --Collection of states for FSM
    type states is (neutral, writing_a, writing_b);
    
    --Two signals for state so that it can be clocked
    signal current_state:		states 																 := neutral;
    signal next_state:			states 																 := neutral;
    
    signal atci_sampled: bcd_digit_vector(13 downto 0)              := (others => bcd_zero);
    signal btci_sampled: bcd_digit_vector(13 downto 0)              := (others => bcd_zero);
    
    signal albi_sampled: bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    signal blbi_sampled: bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    
    signal atsi_sampled: bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);
    signal btsi_sampled: bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);
    
    signal aidi_sampled: byte_vector(0 to 2)                        := (others => byte_unknown);
    signal bidi_sampled: byte_vector(0 to 2)                        := (others => byte_unknown);

    signal next_atci_sampled: bcd_digit_vector(13 downto 0)              := (others => bcd_zero);
    signal next_btci_sampled: bcd_digit_vector(13 downto 0)              := (others => bcd_zero);
    
    signal next_albi_sampled: bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    signal next_blbi_sampled: bcd_digit_vector( 1 downto 0)              := (others => bcd_unknown);
    
    signal next_atsi_sampled: bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);
    signal next_btsi_sampled: bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);
    
    signal next_aidi_sampled: byte_vector(0 to 2)                        := (others => byte_unknown);
    signal next_bidi_sampled: byte_vector(0 to 2)                        := (others => byte_unknown);
    
    signal new_a_data: std_logic := '0';
    signal new_b_data: std_logic := '0';
    
    signal new_a_data_set: std_logic := '0';
    signal new_b_data_set: std_logic := '0';
    
    signal new_a_data_reset: std_logic := '0';
    signal new_b_data_reset: std_logic := '0';
    
    signal next_new_a_data_set: std_logic := '0';
    signal next_new_b_data_set: std_logic := '0';
    
    signal next_new_a_data_reset: std_logic := '0';
    signal next_new_b_data_reset: std_logic := '0';

begin

  process(clk, rst)
  begin
  
  	if (rst = '1') then -- If reset
  	
  		current_state <= neutral;
  		new_a_data <= '0';
  		new_b_data <= '0';
  		atci_sampled <= (others => bcd_zero);
  		albi_sampled <= (others => bcd_unknown);
  		atsi_sampled <= (others => bcd_unknown);
  		aidi_sampled <= (others => byte_unknown);
  		btci_sampled <= (others => bcd_zero);
  		blbi_sampled <= (others => bcd_unknown);
  		btsi_sampled <= (others => bcd_unknown);
  		bidi_sampled <= (others => byte_unknown);
  	
		elsif clk'event and (clk = '1') then	--On clock ri
		
			current_state <= next_state;
			
			atci_sampled <= next_atci_sampled;
  		albi_sampled <= next_albi_sampled;
  		atsi_sampled <= next_atsi_sampled;
  		aidi_sampled <= next_aidi_sampled;
  		btci_sampled <= next_btci_sampled;
  		blbi_sampled <= next_blbi_sampled;
  		btsi_sampled <= next_btsi_sampled;
  		bidi_sampled <= next_bidi_sampled;
  		new_a_data_set		<= next_new_a_data_set;
  		new_a_data_reset	<= next_new_a_data_reset;
  		new_b_data_set		<= next_new_b_data_set;
  		new_b_data_reset	<= next_new_b_data_reset;
			
			if (new_a_data_set = '1') then
			
				new_a_data <= '1';
				
			elsif (new_a_data_reset = '1') then
			
				new_a_data <= '0';
				
			end if;
			
			if (new_b_data_set = '1') then
			
				new_b_data <= '1';
				
			elsif(new_b_data_reset = '1') then
			
				new_b_data <= '0';
				
			end if;
			
		end if;
  
  end process;
  
  --
  
  process(awi, atci, albi, atsi, aidi, atci_sampled, albi_sampled, atsi_sampled, aidi_sampled, new_a_data_set)
  begin
  	
  	next_atci_sampled <= atci_sampled;
		next_albi_sampled <= albi_sampled;
		next_atsi_sampled <= atsi_sampled;
		next_aidi_sampled <= aidi_sampled;
		next_new_a_data_set <= new_a_data_set;
  	
  	if (awi = '1') then
  	
			next_atci_sampled <= atci;
			next_albi_sampled <= albi;
			next_atsi_sampled <= atsi;
			next_aidi_sampled <= aidi;
			next_new_a_data_set <= '1';
			
		end if;
			
  	
  end process;
  
  process(bwi, btci, blbi, btsi, bidi, btci_sampled, blbi_sampled, btsi_sampled, bidi_sampled, new_b_data_set)
  begin
  

  	next_btci_sampled <= btci_sampled;
		next_blbi_sampled <= blbi_sampled;
		next_btsi_sampled <= btsi_sampled;
		next_bidi_sampled <= bidi_sampled;
		next_new_b_data_set <= new_b_data_set;
  
  	if (bwi = '1') then
  	
			next_btci_sampled <= btci;
			next_blbi_sampled <= blbi;
			next_btsi_sampled <= btsi;
			next_bidi_sampled <= bidi;
			next_new_b_data_set <= '1';
			
		end if;
  
  end process;
  
  process(current_state, new_a_data, new_b_data, btsi_sampled, blbi_sampled, btci_sampled, bidi_sampled, atsi_sampled, albi_sampled, atci_sampled, aidi_sampled, bo)
  begin
  
  	wo <= '0';
		next_state <= current_state;
		afi <= '0';		
		bfi <= '0';
		tso <= (others => bcd_zero);
		lbo <= (others => bcd_unknown);
		tco <= (others => bcd_unknown);
		ido <= (others => byte_unknown);
		next_new_a_data_reset <= '0';
		next_new_b_data_reset <= '0';
  
  	case current_state is
  	
  		when neutral =>
  		
  			if (new_a_data = '1') and (bo = '1') then
  				
  				next_state <= writing_a;
  				
  			elsif (new_b_data = '1') and (bo = '1') then
  			
  				next_state <= writing_b;
  				
  			end if;
  			
  		when writing_b =>

				tso <= btsi_sampled;
				lbo <= blbi_sampled;
				tco <= btci_sampled;
				ido <= bidi_sampled;
				bfi <= '1';
				wo <= '1';
				next_new_b_data_reset <= '1';
				next_state <= neutral;
			
			when writing_a =>
				
				tso <= atsi_sampled;
				lbo <= albi_sampled;
				tco <= atci_sampled;
				ido <= aidi_sampled;
				afi <= '1';
				next_new_a_data_reset <= '1';
  			wo <= '1';
  			next_state <= neutral;
  	
  	end case;
  
  end process;

end rtl;
