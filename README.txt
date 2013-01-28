This folder contains two sub-folders - the Template is where the material for putting this project onto hardware (compiled for a Spartan FPGA) and the Test_Signal is for the simulation (needs GHDL, GTKWave).

To run the simulation, just type "make simulation" when inside the Radio_Clock_Test_Signal folder, then "make viewer". You will then see the simulation with the testbench provided.

To upload to hardware, navigate to the Radio_Clock_Template folder and type "make synthesis; make implementation;make bitfile;make upload" after setting up the FPGA appropriately. This will synthesise the VHDL and compile it into a bitfile, which will then be uploaded to the FPGA. You should then use whatever serial-monitoring software you are familiar with to see the output (it is output over serial at standard values). After a minute to sync up, you should see the two signals (MSF and DCF) output every second with the time (HH:MM:SS) and date.
