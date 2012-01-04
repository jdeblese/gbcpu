export XILINX=/opt/Xilinx/13.3/ISE_DS/ISE/
export PLATFORM=lin64
export LD_LIBRARY_PATH=/opt/Xilinx/13.3/ISE_DS/ISE/lib/lin64/

cat > rf16_tb.prj << EOF
vhdl work regfile16bit.vhd
vhdl work regfile16bit_tb.vhd
EOF

fuse -prj rf16_tb.prj -o rf16_tb.exe regfile16bit_tb
./rf16_tb.exe -tclbatch rf16_tb.cmd -view rf16_tb.wcfg -gui
