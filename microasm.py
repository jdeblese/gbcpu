#!/usr/bin/env python

import sys,re

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

bank = {"next" : (0, 10),
        "cmdjmp" : (10, 1),
        "test" : (15,3) }

data = [0] * (maxnib / nnib)
parity = [0] * maxpar

line = '  10 next <= X"3ff", cmdjmp <= \'1\', test <= "101";  \n'

start = re.compile("([0-9]+)[ \t]+(.*)$")
set = re.compile("(([a-zA-Z0-9_]+)[ \t]*<=[ \t]*([xX]?)['\"]([0-9a-fA-F]+)['\"][ \t]*([,;]?))[ \t]*(.*)$")

line = line.strip()
loc,rest = start.match(line).groups()
print loc
while rest != '' :
  all,key,ty,val,delim,rest = set.match(rest).groups()
  sys.stdout.write( "  %s = %s%s (%s)"%(key,val,delim,ty) )
  char = int(loc) * 64
  if ty == '' :
    val = int(val, 2)
  else :
    val = int(val, 16)
  val *= 2**bank[key][0]
  dval = val % maxdval
  pval = val / maxdval
  data[int(loc,16)] += dval;
  parity[int(loc,16) * npar / 4] += pval;
  sys.stdout.write( "  ->  %1.1x"%parity[int(loc,16) * npar / 4] )
  sys.stdout.write( (" %%%d.%dx"%(nnib,nnib))%data[int(loc,16)] + '\n' )
# print data[char:char+nnib]
