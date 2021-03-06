{{ maxbotix_mb1000_demo.spin
┌─────────────────────────────────────────────────┬───────────────────┬─────────┬────────────┐
│ Maxbotix MB1000 simple serial demo v1.0         │ BR                │ (C)2011 │ 23Dec2011  │
├─────────────────────────────────────────────────┴───────────────────┴─────────┴────────────┤
│                                                                                            │
│ Demo showing how to use the serial interface for the maxbotix MB1000 ultrasonic range      │
│ finder in free-running mode. See maxbotix_mb1000.spin for sensor connection schematic.     │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}


CON
    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000

'pin assignments
    mb_pin = 3


OBJ
    Com  : "FullDuplexSerial"
    mb1k : "maxbotix_mb1000"


PUB Start |x

    com.Start(31,30,%0000,115_200) 'UART for talking to the serial terminal
    mb1k.init(mb_pin)

    waitcnt(clkfreq * 5 + cnt)     'wait 5 sec

    Repeat
      com.dec(mb1k.getRange)
      com.tx(13)



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