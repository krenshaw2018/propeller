{{

┌──────────────────────────────────────────┐
│ Quadrature Decoder DEMO                  │
│ Author: Luke Haywas                      │
│                                          │
│                                          │
│ Copyright (c) <2010> <Luke Haywas>       │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

Description:
Demonstrates how to use my object QuadDecoder.
Quadrature encoder is connected to pins 12 and 13.
(If connected to different pins, simply change the
value of ENCODER_PIN below)

Displays value of the accumulated variable in
the serial debug terminal.

}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  '_xinfreq = 6_250_000

  LCD_PIN       = 27
  LCD_BAUD      = 19_200
  LCD_LINES     = 4
  LCD_COLS      = 20

  ENCODER_PIN   = 12

OBJ
  quad  :       "QuadDecoder"
  db    :       "FullDuplexSerial"

VAR
  long  offset                                          ' example variable that will be accumulated to

PUB main

  db.start(31,30,0,115_200)                             ' crank up the debug terminal

  offset := 25                                          ' initialize the accumulator
                                                        ' You can set it to any desired value

  quad.start(ENCODER_PIN, @offset)                      ' start the encoder reader

  ' output to debug terminal:
      
  repeat
    db.str(string(1, "Quadrature Decoder Demo", 13))
    db.str(string("-----------------------", 13, 13))
    db.str(string("Value = "))
    db.dec(offset)
    db.tx(32)
    waitcnt(clkfreq/10 + cnt)

    



{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TERMS OF USE: MIT License │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}