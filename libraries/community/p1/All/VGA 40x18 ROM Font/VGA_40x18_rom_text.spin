{{
vga_40x18_rom_text.spin v1.1 by Roger Williams

This was originally VGA_Text.spin by Chip Gracey.  It has been
modified for compatibility with the 40x18 ROM font VGA driver.
The MIT license still applies.

Aside from the resolution, the major difference is the way colors
are handled.  This driver allows each row to have its own
background, foreground, and alternate color which are defined as
%%rgb from %%000 to %%333.  Within a row, each character can be
either the primary or alternate color, and either normal or
reverse video.

The driver also supports user defined characters defined within
vga_40x18_rom_hc.spin.  These are printed by calling out() with
codes 256 and up, or by using $C to set the user character bank
to an appropriate multiple of 64 for the next or all future
printed characters.  If the user character bank is not zero,
the 4 bit bank value * 64 + 240 is added to printed characters;
this has the effect of making bank 1 "0" output code 256 through
"o" outputting code 511, bank 2 "0" code 512 and so on.  

This is implemented by interpreting the argument of the $C command
byte as follows:

  %0000_00rc or
  %0000_01rc == r 0|1 normal|reverse  c 0|1 normal|alt color
  
  %0001_bbbb == char code %bbb_cccccccc for next character
  %0010_bbbb == char code %bbb_cccccccc until otherwise specified

  %01rr_ggbb == set this line's background color
  %10rr_ggbb == set this line's foreground color
  %11rr_ggbb == set this line's alternate color



A CLS sets all line palettes to that of the first line.  If the line
palette of the first line is changed, the default for future CLS
will change with it.

Revisions:
v1.1 added provisions to $C argument for user character bank switching

}}

CON

  cols = vga#xtiles
  rows = vga#ytiles

  tiles = cols * rows

  screensize = cols * rows
  lastrow = screensize - cols

  defaultrowcolors = %%0000_3330_0220_0000 'waitvid format

' Control characters

  cls           = 0
  home          = 1
  bksp          = 8
  tab           = 9
  CursX         = $A
  CursY         = $B
  mode          = $C
  cr            = $D

  '$C command modes
  
  normal        = %0000_0100
  rvid          = %0000_0010
  altcolor      = %0000_0001
  cbank1        = %0001_0000  
  cbank         = %0010_0000
  setbkg        = %0100_0000
  setfg         = %1000_0000
  setalt        = %1100_0000  
  
VAR

  long  col, row, color, flag

  word  ucbank
  byte  ucbank_ac
  
  word  screen[tiles]
  long  colors[vga#ytiles]

OBJ

  vga : "vga_40x18_rom_rc"


PUB start(basepin, userfontptr) : okay

'' Start terminal - starts a cog
'' returns false if no cog available
''
'' requires 80MHz system clock

  colors := defaultrowcolors
  out(cls)
  
  okay := vga.start(basepin, @screen, @colors, userfontptr)


PUB stop

'' Stop terminal - frees 3 cogs

  vga.stop


PUB str(stringptr)

'' Print a zero-terminated string

  repeat strsize(stringptr)
    out(byte[stringptr++])


PUB dec(value) | i

'' Print a decimal number

  if value < 0
    -value
    out("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      out(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      out("0")
    i /= 10


PUB hex(value, digits)

'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    out(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


PUB bin(value, digits)

'' Print a binary number

  value <<= 32 - digits
  repeat digits
    out((value <-= 1) & 1 + "0")


PUB out(c) | i, k

'' Output a character
''
''     $00 = clear screen
''     $01 = home
''     $08 = backspace
''     $09 = tab (8 spaces per)
''     $0A = set X position (X follows)
''     $0B = set Y position (Y follows)
''     $0C = set color (color follows)
''     $0D = return
''  others = printable characters

  case flag
    $00: case c
           $00: wordfill(@screen, $110, screensize)
                longfill(@colors, colors, rows)
                col := row := ucbank := ucbank_ac := 0
           $01: col := row := 0
           $08: if col
                  col--
           $09: repeat
                  print(" ")
                while col & 7
           $0A..$0C: flag := c
                     return
           $0D: newline
           other: print(c)
    $0A: col := c // cols
    $0B: row := c // rows
    $0C: if (c & %%3000) == 0
           if c & cbank1
             if setucbank(c)
               ucbank_ac := true
           elseif c & cbank
             setucbank(c)
             ucbank_ac := false
           else  
             color := c & 3
         else
           byte[@colors + row*4 + c>>6 -1] := (c & %%333) << 2
  flag := 0

PRI SetUCbank(c)
  ucbank := c & $F
  if ucbank
    ucbank <<= 6
    ucbank += 144
  else
    ucbank_ac := false
  return ucbank

PRI print(c) | pair, lsb, tile

  if col == cols
    newline

  c += ucbank
  if ucbank_ac
    ucbank := 0
   
  pair := c >> 1
  lsb := c & 1
  if c > 255
    pair -= 128
    tile := (color << 1 + lsb) << 10 + pair
  else
    tile := (color << 1 + lsb) << 10 + $100 + pair
  screen[row * cols + col] := tile

  ++col


PRI newline | i

  col := 0
  if ++row == rows
    row--
    wordmove(@screen, @screen[cols], lastrow)   'scroll lines
    wordfill(@screen[lastrow], $220, cols)      'clear new line


{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
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