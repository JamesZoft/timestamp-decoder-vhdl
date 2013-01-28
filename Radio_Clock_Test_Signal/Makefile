TARGET = radio_clock_test_signal

SOURCES =           \
	std_logic_textio.vhd \
	util.vhd \
	bcd_counter.vhd \
	trigger.vhd \
	dcf.vhd \
	msf.vhd \
	mux.vhd \
	radio_clock_test_signal.vhd
	
all help:
	@echo ""
	@echo "Simulation:"
	@echo ""
	@echo "make simulation     - simulate design"
	@echo "make viewer         - start waveform viewer for simulation results"
	@echo ""
	@echo "Cleanup:"
	@echo ""
	@echo "make clean          - delete temporary files and cleanup directory"
	@echo ""

simulation sim:
	@for f in $(SOURCES); do \
	    echo "ghdl -a $$f"; \
	    ghdl -a $$f; \
	done
	ghdl -e $(TARGET)
	ghdl -r $(TARGET) --wave=$(TARGET).ghw

viewer view:
	gtkwave $(TARGET).ghw $(TARGET).sav &
                                                                                                       
clean:
	rm -f *~ *.o $(TARGET) $(TARGET).ghw work-obj93.cf
