cat > falledge_tb.prj << EOF
vhdl work regfile16bit.vhd
vhdl work falledge.vhd
vhdl work falledge_tb.vhd
EOF

fuse -prj falledge_tb.prj -o falledge_tb.exe falledge_tb && \
	./falledge_tb.exe -view falledge_tb.wcfg -log falledge_tb.log -gui
