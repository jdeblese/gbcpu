restart
scope /uut
run 102 ns
run 10 ns
test rfile(2) 0100 -radix hex
run 10 ns
test rfile(2) 010A -radix hex
run 10 ns
