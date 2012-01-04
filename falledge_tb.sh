export XILINX=/opt/Xilinx/13.3/ISE_DS/ISE/
export PLATFORM=lin64
export LD_LIBRARY_PATH=/opt/Xilinx/13.3/ISE_DS/ISE/lib/lin64/

cat > falledge_tb.prj << EOF
vhdl work regfile16bit.vhd
vhdl work falledge.vhd
vhdl work falledge_tb.vhd
EOF

fuse -prj falledge_tb.prj -o falledge_tb.exe falledge_tb && \
	./falledge_tb.exe -view falledge_tb.wcfg -log falledge_tb.log -gui
