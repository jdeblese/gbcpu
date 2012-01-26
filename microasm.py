#!/usr/bin/env python

import sys,re
from copy import copy

start = re.compile("([0-9a-fA-F]+)[ \t]+(.*)$")
set = re.compile("(([a-zA-Z0-9_]+)[ \t]*<=[ \t]*([xX]?)['\"]([0-9a-fA-F]+)['\"][ \t]*([,;]?))[ \t]*(.*)$")

maxnib = 64 * 64
maxpar = 64 * 8

nbits = 18;

if nbits == 36 :
  nnib = 8
  npar = 4
else :
  nnib = nbits / 4;
  npar = nbits % 4;
  assert npar != 3

maxdval = 2**(nnib * 4)

bank = {"next" : (0, 10, 0),
        "cmdjmp" : (10, 1, 0),
        "flsel" : (12, 1, 0),
        "fljmp" : (13, 1, 0),
        "flagsrc" : (11, 1, 0),
        "znhc" : (14, 4, 0),
        "rf_dmux" : (0, 4, 1),
        "rf_imux" : (4, 3, 1),
        "rf_imuxsel" : (7, 1, 1),
        "rf_ce" : (8, 2, 1),
        "rf_amux" : (10, 2, 1),
        "rf_omux" : (12, 3, 1),
        "rf_omuxsel" : (15, 1, 1),
        "alu_cmd" : (0, 6, 2),
        "alu_ce" : (6, 1, 2),
        "cmd_ce" : (8, 1, 2),
        "acc_ce" : (9, 1, 2),
        "tmp_ce" : (10, 1, 2),
        "unq_ce" : (11, 1, 2),
        "wr_en" : (12, 1, 2),
        "dmux" : (13, 3, 2),
        "amux" : (16, 2, 2) }

data = [0] * (maxnib / nnib)
data = (data, copy(data), copy(data))
parity = [0] * maxpar
parity = (parity, copy(parity), copy(parity))
usage = [False] * (maxnib / nnib)

fd = open(sys.argv[1])
line = fd.readline()
linecount = 1
while line != '' and (line == '\n' or line[0] == ';') :
  line = fd.readline()
  linecount += 1

while len(line) > 0 :
  line = line.strip()

  keyhit = copy(bank)
  for k in keyhit.keys() :
    keyhit[k] = False;

  loc,rest = start.match(line).groups()
  addr = int(loc,16)
  paddr = addr * npar / 4
  if addr >= maxnib / nnib :
    raise RuntimeError("Address exceeds bit range, maximum is %x"%(maxnib/nnib-1,))
  if usage[addr] :
    raise RuntimeError("Multiple set of address %x (second on line %d)"%(addr,linecount))
  usage[addr] = True

  setcount = 0;
  while rest != '' :
    setcount += 1;
    try :
      all,key,ty,val,delim,rest = set.match(rest).groups()
    except AttributeError :
      raise RuntimeError('Syntax error on line %d, value %d, rest was "%s"'%(linecount, setcount, rest))
    if keyhit[key] :
      raise RuntimeError('Duplicate key %s on line %d'%(key,linecount))
    keyhit[key] = True
    if ty == '' :
      val = int(val, 2)
    else :
      val = int(val, 16)
    val *= 2**bank[key][0]

    dval = val % maxdval
    pval = val / maxdval * 2**(2*(addr%2))

    data[bank[key][2]][addr] += dval;
    parity[bank[key][2]][paddr] += pval;

  line = fd.readline()
  linecount += 1
  while line != '' and (line == '\n' or line[0] == ';') :
    line = fd.readline()
    linecount += 1


for b in range(0, 3) :
  print "---------- BANK %d ----------"%(b,)
  print "--- Signals: " + ', '.join( filter(lambda k: bank[k][2] == b, bank.keys()) )
  for l in range(0, 8) :
    if l == 0 :
      out = parity[b][63::-1]
    else :
      out = parity[b][(l+1)*64-1:l*64-1:-1]

    print '        INITP_%2.2X => X"'%l + ''.join(map(lambda n: "%1.1x"%n, out)) + '", -- %2.2xh'%(l*64*4/npar,)
  for l in range(0, 64) :
    if l == 0 :
      out = data[b][64/nnib-1::-1]
    else :
      out = data[b][(l+1)*64/nnib-1:l*64/nnib-1:-1]

    print '        INIT_%2.2X => X"'%l + ''.join(map(lambda n: ("%%%d.%dx"%(nnib,nnib))%n, out)) + '", -- %3.3xh'%(l*64/nnib,)

  print "----------------------------"

  print "Memory usage: %d/%d words, %6.2f%%"%(usage.count(True), len(usage), 100.0 * usage.count(True) / len(usage))
