cat > video_tb.prj << EOF
vhdl work video_tb.vhd
vhdl work video.vhd
vhdl work driver.vhd
vhdl work clockgen.vhd
EOF

fuse -prj video_tb.prj -o video_tb.exe video_tb && \
    ./video_tb.exe -view video_tb.wcfg -log video_tb.log  -gui
