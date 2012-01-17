cat > cpu_tb.prj << EOF
vhdl work regfile16bit.vhd
vhdl work alu.vhd
vhdl work microcode.vhd
vhdl work cpu_tb.vhd
EOF

fuse -prj cpu_tb.prj -o cpu_tb.exe cpu_tb && \
    ./cpu_tb.exe -view cpu_tb.wcfg -log cpu_tb.log -gui
