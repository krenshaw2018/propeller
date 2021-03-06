{{ mcp4xxx_simple_demo.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ MCP4xxx digital pot demo v1.0       │ BR             │ (C)2017             │  14Feb2017    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ A simple spin driver for MCP4xxx digital potentiometer chip.                               │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

'hardware constants
cspin = 7
sckpin = 8
sdipin = 9
  
OBJ
  pot : "mcp4xxx_simple"

PUB main | value
  pot.init(cspin, sckpin, sdipin)   'call after prop boot up
  pot.tcon(0,1,1,1,1)               'force pot terminal connections into a known configuration

'  pot.tcon(0,0,1,1,1)               'put pot0 into shutdown mode
'  waitcnt(clkfreq*5 + cnt)

  pot.tcon(0,1,1,1,0)               'disconnect terminal b
  waitcnt(clkfreq*5 + cnt)

  pot.tcon(0,1,0,1,0)               'disconnect terminal a
  waitcnt(clkfreq*5 + cnt)

  pot.tcon(0,1,0,1,0)               'reconnect a,b; disconnect wiper
  waitcnt(clkfreq*5 + cnt)

  pot.tcon(0,1,1,1,1)               'reconnect a,b,wiper
  waitcnt(clkfreq*5 + cnt)

  pot.setpot(0, 0)                  'set min resistance
  waitcnt(clkfreq*5 + cnt)

  pot.setpot(0, 127)                'set resistance to 127
  waitcnt(clkfreq*5 + cnt)

  repeat 128
    pot.decrement(0)
    waitcnt(clkfreq + cnt)
  repeat 128
    pot.increment(0)
    waitcnt(clkfreq + cnt)

DAT
{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}   