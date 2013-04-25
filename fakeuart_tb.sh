cat > uart_tb.prj << EOF
vhdl work fakeuart_tb.vhd
vhdl work fakeuart.vhd
vhdl work clockgen.vhd
EOF

fuse -prj uart_tb.prj -o uart_tb.exe uart_tb && \
    ./uart_tb.exe -view uart_tb.wcfg -log uart_tb.log  -gui
