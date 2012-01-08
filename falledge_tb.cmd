restart
run 100 ns
scope /uut
show value cs
test urf/rfile(4) 0000 -radix hex
run 120 ns
show time
test cs fetch
test urf/rfile(3) fffe -radix hex
test urf/rfile(4) 0003 -radix hex
run 40 ns
show time
show value cs
test acc 00 -radix hex
test urf/rfile(3) fffe -radix hex
test urf/rfile(4) 0004 -radix hex
run 120 ns
show time
show value cs
test acc 00 -radix hex
test urf/rfile(2) 9fff -radix hex
test urf/rfile(3) fffe -radix hex
test urf/rfile(4) 0007 -radix hex
run 1966080 ns
show time
show value cs
test acc 00 -radix hex
test urf/rfile(2) 7fff -radix hex
test urf/rfile(3) fffe -radix hex
test urf/rfile(4) 000c -radix hex
quit
