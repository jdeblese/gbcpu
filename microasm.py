#!/usr/bin/env python

import sys,re

start = re.compile("([0-9a-fA-F]+)[ \t]+(.*)$")
set = re.compile("(([a-zA-Z0-9_]+)[ \t]*<=[ \t]*([xX]?)['\"]([0-9a-fA-F]+)['\"][ \t]*([,;]?))[ \t]*(.*)$")
  
maxnib = 64 * 64
maxpar = 64 * 8

nbits = 36;

if nbits == 36 :
  nnib = 8
  npar = 4
else :
  nnib = nbits / 4;
  npar = nbits % 4;
  assert npar != 3

maxdval = 2**(nnib * 4)

bank = {"next" : (0, 9),
        "cmdjmp" : (10, 1),
        "rf_omux" : (11, 3),
        "rf_imuxsel" : (14, 1),
        "rf_imux" : (15, 3),
        "rf_amux" : (18, 2),
        "rf_ce" : (20, 2),
        "alu_cmd" : (22, 9),
        "alu_ce" : (31, 1),
        "rf_dmux" : (32, 4) }

data = [0] * (maxnib / nnib)
parity = [0] * maxpar

fd = open(sys.argv[1])
line = fd.readline()
linecount = 1
while line != '' and (line == '\n' or line[0] == ';') :
  line = fd.readline()
  linecount += 1

while len(line) > 0 :
  line = line.strip() 
  loc,rest = start.match(line).groups()
  setcount = 0;
  while rest != '' :
    setcount += 1;
    try :
      all,key,ty,val,delim,rest = set.match(rest).groups()
    except AttributeError :
      raise RuntimeError("Syntax error on line %d, value %d"%(linecount, setcount))
    if ty == '' :
      val = int(val, 2)
    else :
      val = int(val, 16)
    val *= 2**bank[key][0]
    dval = val % maxdval
    pval = val / maxdval
    addr = int(loc,16)
    if addr >= maxnib / nnib :
      raise RuntimeError("Address exceeds bit range, maximum is %x"%(maxnib/nnib-1,))
    data[addr] += dval;
    parity[addr * npar / 4] += pval;

  line = fd.readline()
  linecount += 1
  while line != '' and (line == '\n' or line[0] == ';') :
    line = fd.readline()
    linecount += 1

for l in range(0, 64) :
  if l == 0 :
    out = data[64/nnib-1::-1]
  else :
    out = data[(l+1)*64/nnib-1:l*64/nnib-1:-1]

  print 'INIT_%2.2X => X"'%l + ''.join(map(lambda n: ("%%%d.%dx"%(nnib,nnib))%n, out)) + '"'

for l in range(0, 8) :
  if l == 0 :
    out = parity[63::-1]
  else :
    out = parity[(l+1)*64-1:l*64-1:-1]

  print 'INITP_%2.2X => X"'%l + ''.join(map(lambda n: "%1.1x"%n, out)) + '"'
