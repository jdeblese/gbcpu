#!/usr/bin/env python

import sys,re
from copy import copy

start = re.compile("([0-9a-fA-F]+)[ \t]+(.*)$")
set = re.compile("(([a-zA-Z0-9_]+)[ \t]*<=[ \t]*([xX]?)['\"]([0-9a-fA-F]+)['\"])")

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
        "rf_imuxsel" : (16, 2, 1),
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

aliasmapping = {"flags":"znhc"}

aliases = {"dmux" : {"ram":0, "rf":1, "acc":2, "alu":3, "tmp":4, "unq":5, "fixed":6, "zhnc":7},
           "flags" : {"nh":6, "nhc":7, "zhc":11, "znh":14, "znhc":15},
           "rf_imuxsel" : {"imux":0, "cmd[5:4]":1, "cmd[2:1]":2},
           "rf_imux" : {"bc":0, "de":1, "hl":2, "sp":3, "pc":4},
           "rf_omux" : {"bc":0, "de":1, "hl":2, "sp":3, "pc":4},
           "rf_amux" : {"idata":0, "hl":1, "dec":2, "inc":3},
           "rf_ce" : {"lo":1, "hi":2, "both":3},
           "rf_dmux" : {"b":0, "c":1, "d":2, "e":3, "h":4, "l":5, "sp_hi":6, "sp_lo":7, "pc_hi":8, "pc_lo":9, "x":15}}

singles = {'jcmd' : (('cmdjmp', 1),),
           'jzero' : (('fljmp', 1), ('flsel', 1)),
           'jcarry' : (('fljmp', 1), ('flsel', 0)),
           'rf_ce' : (('rf_ce', 3),),
           'wr' : (('wr_en', 1),),
           'aluflags' : (('flagsrc', 0),),
           'rfflags' : (('flagsrc', 1),),
           'store_acc' : (('acc_ce', 1),),
           'store_alu' : (('alu_ce', 1),),
           'store_cmd' : (('cmd_ce', 1),),
           'store_tmp' : (('tmp_ce', 1),),
           'store_unq' : (('unq_ce', 1),) }

data = [0] * (maxnib / nnib)
data = (data, copy(data), copy(data))
parity = [0] * maxpar
parity = (parity, copy(parity), copy(parity))
usage = [False] * (maxnib / nnib)

# Find the first line of assembler
fd = open(sys.argv[1])
line = fd.readline()
linecount = 1

def insertcmd(key, val, addr, keyhit) :
    # Check for duplicate commands on one line
    if keyhit[key] :
      raise RuntimeError('Duplicate key %s on line %d'%(key,linecount))
    keyhit[key] = True

    val *= 2**bank[key][0]

    dval = val % maxdval
    pval = val / maxdval * 2**(2*(addr%2))

    data[bank[key][2]][addr] += dval;
    parity[bank[key][2]][paddr] += pval;

while line != '' and (line == '\n' or line[0] == ';') :
  line = fd.readline()
  linecount += 1

while len(line) > 0 :
  line = line.strip()

  keyhit = copy(bank)
  for k in keyhit.keys() :
    keyhit[k] = False;

  # Use regex to extract the memory location
  try :
    loc,rest = start.match(line).groups()
  except :
    raise RuntimeError('Problem parsing string "%s"'%line)

  addr = int(loc,16)
  paddr = addr * npar / 4
  if addr >= maxnib / nnib :
    raise RuntimeError("Address exceeds bit range, maximum is %x"%(maxnib/nnib-1,))
  if usage[addr] :
    raise RuntimeError("Multiple set of address %x (second on line %d)"%(addr,linecount))
  usage[addr] = True

  cmds = [s.strip() for s in rest.split(',')]

  setcount = 0;
  for cmd in cmds :
    setcount += 1;
    splitcmd = cmd.lower().split(' ')
    if splitcmd[0] == 'jmp' :
      insertcmd('next', int(splitcmd[1],16), addr, keyhit)
    elif len(splitcmd) == 1 and splitcmd[0] in singles.keys() :
      for target in singles[splitcmd[0]] :
        key,val = target
        insertcmd(key, val, addr, keyhit)
    elif len(splitcmd) == 2 and splitcmd[0] in aliases.keys() and splitcmd[1] != '<=' :
      key = splitcmd[0]
      try :
        val = aliases[key][splitcmd[1]]
      except KeyError :
        raise RuntimeError('Syntax error on line %d, term %d (address %x). Command was "%s"'%(linecount, setcount, addr, cmd))
      if key in aliasmapping.keys() :
        key = aliasmapping[key]
      insertcmd(key, val, addr, keyhit)
    else :
      try :
        all,key,ty,val = set.match(cmd).groups()
      except AttributeError :
        raise RuntimeError('Syntax error on line %d, term %d (address %x). Command was "%s"'%(linecount, setcount, addr, cmd))
      if ty == '' :
        val = int(val, 2)
      else :
        val = int(val, 16)
      insertcmd(key, val, addr, keyhit)

  line = fd.readline()
  linecount += 1
  while line != '' and (line == '\n' or line[0] == ';') :
    line = fd.readline()
    linecount += 1

# Formatted output
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

  print "Memory usage: %d/%d words, %6.2f%%, %d left"%(usage.count(True), len(usage), 100.0 * usage.count(True) / len(usage), len(usage) - usage.count(True))
