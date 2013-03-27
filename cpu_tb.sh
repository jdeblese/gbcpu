cat > cpu_tb.prj << EOF
vhdl work cpu.vhd
vhdl work cpuregs.vhd
vhdl work regfile16bit.vhd
vhdl work alu.vhd
vhdl work microcode.vhd
vhdl work cpu_tb.vhd
vhdl work timer.vhd
vhdl work video.vhd
vhdl work driver.vhd
vhdl work clockgen.vhd
vhdl work system.vhd
vhdl work cartram.vhd
vhdl work sysram.vhd
vhdl work types.vhd
EOF

fuse -prj cpu_tb.prj -o cpu_tb.exe cpu_tb && \
    ./cpu_tb.exe -view cpu_tb.wcfg -log cpu_tb.log # -gui
