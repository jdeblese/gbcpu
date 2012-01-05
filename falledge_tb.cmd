restart
scope /uut
marker add 100 ns
marker add 140 ns
marker add 180 ns
marker add 260 ns
marker add 340 ns
marker add 460 ns
marker add 540 ns
marker add 580 ns
marker add 660 ns
marker add 740 ns
marker add 820 ns
marker add 900 ns
marker add 980 ns
marker add 1060 ns
marker add 1140 ns
run 940 ns
show time
test acc 80 -radix hex
test tmp 0b -radix hex
test urf/rfile(0) 0000 -radix hex
test urf/rfile(1) ff00 -radix hex
test urf/rfile(2) 0019 -radix hex
test urf/rfile(3) 0000 -radix hex
test urf/rfile(4) 0017 -radix hex
run 200 ns
show time
test acc 80 -radix hex
test tmp 0b -radix hex
test urf/rfile(0) 0080 -radix hex
test urf/rfile(1) ff00 -radix hex
test urf/rfile(2) 0019 -radix hex
test urf/rfile(3) 0000 -radix hex
test urf/rfile(4) 001a -radix hex
run 300 ns
show time
test urf/rfile(0) 88aa -radix hex
test urf/rfile(1) ff00 -radix hex
test urf/rfile(3) fffe -radix hex
run 100 ns
show time
test acc 80 -radix hex
test tmp 0b -radix hex
test urf/rfile(0) 88aa -radix hex
test urf/rfile(1) 88aa -radix hex
test urf/rfile(2) 0019 -radix hex
test urf/rfile(3) 0000 -radix hex
test urf/rfile(4) 001f -radix hex
quit
