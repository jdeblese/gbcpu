cat > fakeuart_tb.prj << EOF
vhdl work fakeuart_tb.vhd
vhdl work fakeuart.vhd
vhdl work clockgen.vhd
EOF

fuse -prj fakeuart_tb.prj -o fakeuart_tb.exe fakeuart_tb && \
    ./fakeuart_tb.exe -view fakeuart_tb.wcfg -log fakeuart_tb.log  -gui
