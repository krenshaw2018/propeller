''**************************************
''
''  8-Bit graphics driver Ver. 00.0
''
''  Timothy D. Swieter, E.I.
''  www.brilldea.com
''
''  Copyright (c) 2008 Timothy D. Swieter, E.I.
''  See end of file for terms of use. 
''
''  Updated: March 18, 2008
''
''Description:
''      This program is an 8-bit graphics driver. 
''
''Reference:
''      Parallax "Graphics.spin"
''      Game Programming for the Propeller Powered Hydra by Andre LaMothe
''      uOLED-96-PROP_V4.spin
''      Parallax Forum (Paul Sr. Posts and others)
''
''Revision Notes:
'' 0.0 Begin coding SPIN routines
''
''
''TO DO:
'' - Make a fill type of command
'' - Write engine and functions in ASM (NEED MORE SPEED!) (use Parallax Graphics as "template")
'' - Add clipping of image when rendering into the video memory
''
''
'**************************************
CON               'Constants to be located here
'***************************************
'  System Definitions      
'***************************************

  _OUTPUT       = 1             'Sets pin to output in DIRA register
  _INPUT        = 0             'Sets pin to input in DIRA register  
  _HIGH         = 1             'High=ON=1=3.3v DC
  _ON           = 1
  _LOW          = 0             'Low=OFF=0=0v DC
  _OFF          = 0
  _ENABLE       = 1             'Enable (turn on) function/mode
  _DISABLE      = 0             'Disable (turn off) function/mode
  

'**************************************
VAR               'Variables to be located here
'**************************************

  'Processor
  long  GRAPHICS_cog            'Cog flag/ID

  'Graphics routine
  long  Xtiles                  'Number of x tiles, each tile is 4 pixels by 4 pixels
  long  Ytiles                  'Number of y tiles, each tile is 4 pixels by 4 pixels
  long  BitmapBase              'Address of the start of the bitmap video memory
  long  BitmapLongs             'Number of longs in the bitmap video memory
  

OBJ               'Object declaration to be located here
'**************************************

  'None
  
'**************************************
PUB start : okay
'**************************************
'' Start the ASM display driver for the graphics display
'' returns cog ID (1-8) if good or 0 if no good
'' remember to run setup to initialize the display with the proper data

' stop                                                  'Keeps two cogs from running at the same time

  'Start a cog with assembly routine
' okay:= GRAPHICS_cog:= cognew(@ENTRY, @command) + 1    'Returns 0-8 depending on success/failure


'**************************************
PUB stop
'**************************************
'' Stops ASM graphics driver - frees a cog

' if GRAPHICS_cog                                       'Is cog non-zero?  
'   cogstop(GRAPHICS_cog~ - 1)                          'Stop the cog and then make value of flag zero


'**************************************
PUB setup(_xtiles, _ytiles, _baseptr)
'**************************************
'' Setup the bitmap parameters for the graphics driver, must be run
''
''  _xtiles    - number of x tiles (tiles are 4 x 4 pixels each because 8-bits x 4 pixes = long)
''  _ytiles    - number of y tilesl
''  _baseptr   - base address of bitmap

  Xtiles := _xtiles
  Ytiles := _ytiles
  
  BitmapBase := _baseptr                                'Calculate the values to be used by other routines
  BitmapLongs := _xtiles * (_ytiles << 2)

  
'**************************************
PUB clear
'**************************************
'' Clear bitmap (write zeros to all pixels)

  longfill(BitmapBase, 0, BitmapLongs)                  'Fill the bitmap with zeros

  
'**************************************
PUB copy(_destptr)
'**************************************
'' Copy bitmap to new location for use as double-buffered display (flicker-free)
''
''  _destptr   - base address of destination bitmap

  longmove(_destptr, BitmapBase, BitmapLongs)           'Copy bitmap to new destination


'**************************************
PUB plotPixel(_x0, _y0, _color) | videoOffset, pixelValue
'**************************************
'' Plot at pixel at x, y, with the appropriate 8-bit color
''
''  _x         - coordinate of the pixel
''  _y         - coordinate of the pixel
''  _color     - 8-bit color value (RRRGGGBB)


  'This byte version work
  videoOffset := BitmapBase + (_x0 >> 2) * (Ytiles << 4) + (_x0 & %11) + (_y0 << 2)
  pixelValue := byte[videoOffset]
  pixelValue := (_color & $FF)
  byte[videoOffset] := pixelValue

{
  'This long version works
  videoOffset := (BitmapBase >> 2) + (_x >> 2) * (Ytiles << 2) + _y
  pixelValue := long[0][videoOffset]
  pixelValue := pixelValue & !($ff << ((_x & %11) << 3))
  pixelValue := pixelValue | ((_color &$FF) << ((_x & %11) << 3))
  long[0][videoOffset] := pixelValue
}


'**************************************
PUB plotLine(_x0, _y0, _x1, _y1, _color) | dx, dy, difx, dify, sx, sy, ds
'**************************************
'' Plot a line from _x0,_y0 to _x1,_y1 with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the start pixel
''  _x1, _y1   - coordinate of the end pixel
''  _color     - 8-bit color value (RRRGGGBB)
''
''  Based on routine from Phil on Parallax Forum

  difx := ||(_x0 - _x1)         'Number of pixels in X direciton.
  dify := ||(_y0 - _y1)         'Number of pixels in Y direction.
  ds := difx <# dify            'State variable change: smaller of difx and dify.
  sx := dify >> 1               'State variables: >>1 to split remainders between line ends.
  sy := difx >> 1
  dx := (_x1 < _x0) | 1         'X direction: -1 or 1
  dy := (_y1 < _y0) | 1         'Y direction: -1 or 1
  
  repeat (difx #> dify) + 1     'Number of pixels to draw is greater of difx and dify, plus one.
    plotPixel(_x0, _y0, _color) 'Draw the current point.
    if ((sx -= ds) =< 0)        'Subtract ds from x state. =< 0 ?
      sx += dify                '  Yes: Increment state by dify.
      _x0 += dx                 '       Move X one pixel in X direciton.
    if ((sy -= ds) =< 0)        'Subtract ds from y state. =< 0 ?
      sy += difx                '  Yes: Increment state by difx.
      _y0 += dy                 '       Move Y one pixel in Y direction.
      

'**************************************
PUB plotCircle(_x0, _y0, _radius, _color) | sum, x, y
'**************************************
'' Plot a circle with center _x0,_y0 and radius _radius with the appropriate 8-bit color
''
''  _x0, _y0   - coordinate of the center of the circle
''  _radius    - radius, in pixels, of the circle
''  _color     - 8-bit color value (RRRGGGBB)
''
''  Based on routines from Paul Sr. on Parallax Forum

  x := 0
  y := _radius
  sum := (5-_radius*4)/4

  circleHelper(_x0, _y0, x, y, _color)
  
  repeat while (x < y) 
    x++
    if (sum < 0) 
      sum += 2*x+1
    else 
       y--
       sum += 2*(x-y)+1
    circleHelper(_x0, _y0, x, y, _color)
  circleHelper(_x0, _y0, x, y, _color)
    
    
'**************************************
PUB plotSprite(_x0, _y0, _spritePTR) | xpix, ypix, x, y
'**************************************
'' Plot a pixel sprite into the video memory.
''
''  _x0, _y0   - coordinate of the center of the sprite
''  _spritePTR - pointer to pixel sprite memory location
''    
''  long
''  byte xpixels, ypixels, xorigin, yorigin
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  long %RRRGGGBB, %RRRGGGBB, %RRRGGGBB, %RRRGGGBB
''  .... 

  xpix := byte[_spritePTR][0]
  ypix := byte[_spritePTR][1]

  repeat y from 0 to ypix-1
    repeat x from 0 to xpix-1
      plotPixel(_x0+x, _y0+y, byte[_spritePTR][4+x+(xpix*y)])


'**************************************
PUB plotChar(_char, _xC, _yC, _font, _color) | row, col
'**************************************
'' Plot a single character into the video memory.
''
''  _char      - The character
''  _xC        - Text column (0-11 for 8x8 font, 0-15 for 5x7 font)
''  _yC        - Text row (0-7 for 8x8 and 5x7 font)
''  _font      - The font, if 1 then 8x8, else 5x7
''  _color     - 8-bit color value (RRRGGGBB)
''
''  Based on routines from 4D System uOLED driver    

   _char := (_char - " ") << 3
   if _font                                             ' font 1 8x8 
      _xC <<= 3                                         ' x 8
      _yC <<= 3                                         ' x 8
      repeat row from 0 to 7
         repeat col from 0 to 7
            if font_8x8[_char+row] & $80 >> col
               plotPixel(_xC+col,_yC+row, _color)
   else                                                 ' font 0 5x7
      _xC *= 6                                          ' x 6
      _yC *= 8                                          ' x 7
      repeat row from 0 to 7
         repeat col from 1 to 6
            if font_5x7[_char+row] & $01 << col
               plotPixel(_xC+col,_yC+row, _color)
               

PUB plotText (_xC, _yC, _font, _color, _str) | t
'' Plot a string of characters into the video memory.
''
''  _xC        - Text column (0-11 for 8x8 font, 0-15 for 5x7 font)
''  _yC        - Text row (0-7 for 8x8 and 5x7 font)
''  _font      - The font, if 1 then 8x8, else 5x7
''  _color     - 8-bit color value (RRRGGGBB)
''  _str       - String of characters
''
''  Based on routines from 4D System uOLED driver

  repeat strsize(_str)
    plotChar((byte[_str++]), _xC++, _yC, _font, _color)
     if _font
        if _xC > 95 / 8
          _xC := 0
          _yC += 1
     elseif _xC > 95 / 6
       _xC := 0
       _yC += 1


'**************************************
PRI circleHelper(_cx, _cy, _x, _y, _color)
'**************************************
'' helps to draw a circle on the screen, used with plotcircle
'' Based on routiness from Paul Sr. on Parallax Forum

  if (_x == 0) 
    plotPixel(_cx, _cy + _y, _color)
    plotPixel(_cx, _cy - _y, _color)
    plotPixel(_cx + _y, _cy, _color)
    plotPixel(_cx - _y, _cy, _color)
  else 
  if (_x == _y) 
    plotPixel(_cx + _x, _cy + _y, _color)
    plotPixel(_cx - _x, _cy + _y, _color)
    plotPixel(_cx + _x, _cy - _y, _color)
    plotPixel(_cx - _x, _cy - _y, _color)
  else 
  if (_x < _y) 
    plotPixel(_cx + _x, _cy + _y, _color)
    plotPixel(_cx - _x, _cy + _y, _color)
    plotPixel(_cx + _x, _cy - _y, _color)
    plotPixel(_cx - _x, _cy - _y, _color)
    plotPixel(_cx + _y, _cy + _x, _color)
    plotPixel(_cx - _y, _cy + _x, _color)
    plotPixel(_cx + _y, _cy - _x, _color)
    plotPixel(_cx - _y, _cy - _x, _color)


'**************************************
DAT
'**************************************

font_8x8      byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00110000,%00110000,%00110000,%00110000,%00110000,%00000000,%00110000,%00000000
              byte %01101100,%01101100,%01101100,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %01101100,%01101100,%11111110,%01101100,%11111110,%01101100,%01101100,%00000000
              byte %00110000,%01111100,%11000000,%01111000,%00001100,%11111000,%00110000,%00000000
              byte %00000000,%11000110,%11001100,%00011000,%00110000,%01100110,%11000110,%00000000
              byte %00111000,%01101100,%00111000,%01110110,%11011100,%11001100,%01110110,%00000000
              byte %01100000,%01100000,%11000000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00011000,%00110000,%01100000,%01100000,%01100000,%00110000,%00011000,%00000000
              byte %01100000,%00110000,%00011000,%00011000,%00011000,%00110000,%01100000,%00000000
              byte %00000000,%01100110,%00111100,%11111111,%00111100,%01100110,%00000000,%00000000
              byte %00000000,%00110000,%00110000,%11111100,%00110000,%00110000,%00000000,%00000000
              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00110000,%00110000,%01100000
              byte %00000000,%00000000,%00000000,%11111100,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00110000,%00110000,%00000000
              byte %00000100,%00001100,%00011000,%00110000,%01100000,%11000000,%10000000,%00000000
              byte %01111100,%11000110,%11001110,%11011110,%11110110,%11100110,%01111100,%00000000
              byte %00110000,%01110000,%00110000,%00110000,%00110000,%00110000,%11111100,%00000000
              byte %01111000,%11001100,%00001100,%00111000,%01100000,%11001100,%11111100,%00000000
              byte %01111000,%11001100,%00001100,%00111000,%00001100,%11001100,%01111000,%00000000
              byte %00011100,%00111100,%01101100,%11001100,%11111110,%00001100,%00011110,%00000000
              byte %11111100,%11000000,%11111000,%00001100,%00001100,%11001100,%01111000,%00000000
              byte %00111000,%01100000,%11000000,%11111000,%11001100,%11001100,%01111000,%00000000
              byte %11111100,%11001100,%00001100,%00011000,%00110000,%00110000,%00110000,%00000000
              byte %01111000,%11001100,%11001100,%01111000,%11001100,%11001100,%01111000,%00000000
              byte %01111000,%11001100,%11001100,%01111100,%00001100,%00011000,%01110000,%00000000
              byte %00000000,%00110000,%00110000,%00000000,%00000000,%00110000,%00110000,%00000000
              byte %00000000,%00110000,%00110000,%00000000,%00000000,%00110000,%00110000,%01100000
              byte %00011000,%00110000,%01100000,%11000000,%01100000,%00110000,%00011000,%00000000
              byte %00000000,%00000000,%11111100,%00000000,%00000000,%11111100,%00000000,%00000000
              byte %01100000,%00110000,%00011000,%00001100,%00011000,%00110000,%01100000,%00000000
              byte %01111000,%11001100,%00001100,%00011000,%00110000,%00000000,%00110000,%00000000
              byte %01111100,%11000110,%11011110,%11011110,%11011110,%11000000,%01111000,%00000000
              byte %00110000,%01111000,%11001100,%11001100,%11111100,%11001100,%11001100,%00000000
              byte %11111100,%01100110,%01100110,%01111100,%01100110,%01100110,%11111100,%00000000
              byte %00111100,%01100110,%11000000,%11000000,%11000000,%01100110,%00111100,%00000000
              byte %11111000,%01101100,%01100110,%01100110,%01100110,%01101100,%11111000,%00000000
              byte %01111110,%01100000,%01100000,%01111000,%01100000,%01100000,%01111110,%00000000
              byte %01111110,%01100000,%01100000,%01111000,%01100000,%01100000,%01100000,%00000000
              byte %00111100,%01100110,%11000000,%11000000,%11001110,%01100110,%00111110,%00000000
              byte %11001100,%11001100,%11001100,%11111100,%11001100,%11001100,%11001100,%00000000
              byte %01111000,%00110000,%00110000,%00110000,%00110000,%00110000,%01111000,%00000000
              byte %00011110,%00001100,%00001100,%00001100,%11001100,%11001100,%01111000,%00000000
              byte %11100110,%01100110,%01101100,%01111000,%01101100,%01100110,%11100110,%00000000
              byte %01100000,%01100000,%01100000,%01100000,%01100000,%01100000,%01111110,%00000000
              byte %11000110,%11101110,%11111110,%11111110,%11010110,%11000110,%11000110,%00000000
              byte %11000110,%11100110,%11110110,%11011110,%11001110,%11000110,%11000110,%00000000
              byte %00111000,%01101100,%11000110,%11000110,%11000110,%01101100,%00111000,%00000000
              byte %11111100,%01100110,%01100110,%01111100,%01100000,%01100000,%11110000,%00000000
              byte %01111000,%11001100,%11001100,%11001100,%11011100,%01111000,%00011100,%00000000
              byte %11111100,%01100110,%01100110,%01111100,%01101100,%01100110,%11100110,%00000000
              byte %01111000,%11001100,%11100000,%01111000,%00011100,%11001100,%01111000,%00000000
              byte %11111100,%00110000,%00110000,%00110000,%00110000,%00110000,%00110000,%00000000
              byte %11001100,%11001100,%11001100,%11001100,%11001100,%11001100,%11111100,%00000000
              byte %11001100,%11001100,%11001100,%11001100,%11001100,%01111000,%00110000,%00000000
              byte %11000110,%11000110,%11000110,%11010110,%11111110,%11101110,%11000110,%00000000
              byte %11000110,%11000110,%01101100,%00111000,%00111000,%01101100,%11000110,%00000000
              byte %11001100,%11001100,%11001100,%01111000,%00110000,%00110000,%01111000,%00000000
              byte %11111110,%00000110,%00001100,%00011000,%00110000,%01100000,%11111110,%00000000
              byte %01111000,%01100000,%01100000,%01100000,%01100000,%01100000,%01111000,%00000000
              byte %11000000,%01100000,%00110000,%00011000,%00001100,%00000110,%00000010,%00000000
              byte %01111000,%00011000,%00011000,%00011000,%00011000,%00011000,%01111000,%00000000
              byte %00010000,%00111000,%01101100,%11000110,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%11111111
              byte %00110000,%00110000,%00011000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%00000000,%01111000,%00001100,%01111100,%11001100,%01110110,%00000000
              byte %11100000,%01100000,%01100000,%01111100,%01100110,%01100110,%11011100,%00000000
              byte %00000000,%00000000,%01111000,%11001100,%11000000,%11001100,%01111000,%00000000
              byte %00011100,%00001100,%00001100,%01111100,%11001100,%11001100,%01110110,%00000000
              byte %00000000,%00000000,%01111000,%11001100,%11111100,%11000000,%01111000,%00000000
              byte %00111000,%01101100,%01100000,%11110000,%01100000,%01100000,%11110000,%00000000
              byte %00000000,%00000000,%01110110,%11001100,%11001100,%01111100,%00001100,%11111000
              byte %11100000,%01100000,%01101100,%01110110,%01100110,%01100110,%11100110,%00000000
              byte %00110000,%00000000,%01110000,%00110000,%00110000,%00110000,%01111000,%00000000
              byte %00001100,%00000000,%00001100,%00001100,%00001100,%11001100,%11001100,%01111000
              byte %11100000,%01100000,%01100110,%01101100,%01111000,%01101100,%11100110,%00000000
              byte %01110000,%00110000,%00110000,%00110000,%00110000,%00110000,%01111000,%00000000
              byte %00000000,%00000000,%11001100,%11111110,%11111110,%11010110,%11000110,%00000000
              byte %00000000,%00000000,%11111000,%11001100,%11001100,%11001100,%11001100,%00000000
              byte %00000000,%00000000,%01111000,%11001100,%11001100,%11001100,%01111000,%00000000
              byte %00000000,%00000000,%11011100,%01100110,%01100110,%01111100,%01100000,%11110000
              byte %00000000,%00000000,%01110110,%11001100,%11001100,%01111100,%00001100,%00011110
              byte %00000000,%00000000,%11011100,%01110110,%01100110,%01100000,%11110000,%00000000
              byte %00000000,%00000000,%01111100,%11000000,%01111000,%00001100,%11111000,%00000000
              byte %00010000,%00110000,%01111100,%00110000,%00110000,%00110100,%00011000,%00000000
              byte %00000000,%00000000,%11001100,%11001100,%11001100,%11001100,%01110110,%00000000
              byte %00000000,%00000000,%11001100,%11001100,%11001100,%01111000,%00110000,%00000000
              byte %00000000,%00000000,%11000110,%11010110,%11111110,%11111110,%01101100,%00000000
              byte %00000000,%00000000,%11000110,%01101100,%00111000,%01101100,%11000110,%00000000
              byte %00000000,%00000000,%11001100,%11001100,%11001100,%01111100,%00001100,%11111000
              byte %00000000,%00000000,%11111100,%10011000,%00110000,%01100100,%11111100,%00000000
              byte %00011100,%00110000,%00110000,%11100000,%00110000,%00110000,%00011100,%00000000
              byte %00011000,%00011000,%00011000,%00000000,%00011000,%00011000,%00011000,%00000000
              byte %11100000,%00110000,%00110000,%00011100,%00110000,%00110000,%11100000,%00000000
              byte %01110110,%11011100,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
              byte %00000000,%01100110,%01100110,%01100110,%01100110,%01100110,%01011100,%10000000

font_5x7      byte $00,$00,$00,$00,$00,$00,$00,$00  ' space
              byte $02,$02,$02,$02,$02,$00,$02,$00  '  "!"
              byte $36,$12,$24,$00,$00,$00,$00,$00  '  """
              byte $00,$14,$3E,$14,$3E,$14,$00,$00  '  "#"
              byte $08,$3C,$0A,$1C,$28,$1E,$08,$00  '  "$"
              byte $22,$22,$10,$08,$04,$22,$22,$00  '  "%"
              byte $04,$0A,$0A,$04,$2A,$12,$2C,$00  '  "&"
              byte $18,$10,$08,$00,$00,$00,$00,$00  '  "'"
              byte $20,$10,$08,$08,$08,$10,$20,$00  '  "("
              byte $02,$04,$08,$08,$08,$04,$02,$00  '  ")"
              byte $00,$08,$2A,$1C,$1C,$2A,$08,$00  '  "*"
              byte $00,$08,$08,$3E,$08,$08,$00,$00  '  "+"
              byte $00,$00,$00,$00,$00,$06,$04,$02  '  ","
              byte $00,$00,$00,$3E,$00,$00,$00,$00  '  "-"
              byte $00,$00,$00,$00,$00,$06,$06,$00  '  "."
              byte $20,$20,$10,$08,$04,$02,$02,$00  '  "/"
              byte $1C,$22,$32,$2A,$26,$22,$1C,$00  '  "0"
              byte $08,$0C,$08,$08,$08,$08,$1C,$00  '  "1"
              byte $1C,$22,$20,$10,$0C,$02,$3E,$00  '  "2"
              byte $1C,$22,$20,$1C,$20,$22,$1C,$00  '  "3"
              byte $10,$18,$14,$12,$3E,$10,$10,$00  '  "4"
              byte $3E,$02,$1E,$20,$20,$22,$1C,$00  '  "5"
              byte $18,$04,$02,$1E,$22,$22,$1C,$00  '  "6"
              byte $3E,$20,$10,$08,$04,$04,$04,$00  '  "7"
              byte $1C,$22,$22,$1C,$22,$22,$1C,$00  '  "8"
              byte $1C,$22,$22,$3C,$20,$10,$0C,$00  '  "9"
              byte $00,$06,$06,$00,$06,$06,$00,$00  '  ":"
              byte $00,$06,$06,$00,$06,$06,$04,$02  '  ";"
              byte $20,$10,$08,$04,$08,$10,$20,$00  '  "<"
              byte $00,$00,$3E,$00,$3E,$00,$00,$00  '  "="
              byte $02,$04,$08,$10,$08,$04,$02,$00  '  ">"
              byte $1C,$22,$20,$10,$08,$00,$08,$00  '  "?"
              byte $1C,$22,$2A,$2A,$1A,$02,$3C,$00  '  "@"
              byte $08,$14,$22,$22,$3E,$22,$22,$00  '  "A"
              byte $1E,$22,$22,$1E,$22,$22,$1E,$00  '  "B"
              byte $18,$24,$02,$02,$02,$24,$18,$00  '  "C"
              byte $0E,$12,$22,$22,$22,$12,$0E,$00  '  "D"
              byte $3E,$02,$02,$1E,$02,$02,$3E,$00  '  "E"
              byte $3E,$02,$02,$1E,$02,$02,$02,$00  '  "F"
              byte $1C,$22,$02,$02,$32,$22,$1C,$00  '  "G"
              byte $22,$22,$22,$3E,$22,$22,$22,$00  '  "H"
              byte $3E,$08,$08,$08,$08,$08,$3E,$00  '  "I"
              byte $20,$20,$20,$20,$20,$22,$1C,$00  '  "J"
              byte $22,$12,$0A,$06,$0A,$12,$22,$00  '  "K"
              byte $02,$02,$02,$02,$02,$02,$3E,$00  '  "L"
              byte $22,$36,$2A,$2A,$22,$22,$22,$00  '  "M"
              byte $22,$22,$26,$2A,$32,$22,$22,$00  '  "N"
              byte $1C,$22,$22,$22,$22,$22,$1C,$00  '  "O"
              byte $1E,$22,$22,$1E,$02,$02,$02,$00  '  "P"
              byte $1C,$22,$22,$22,$2A,$12,$2C,$00  '  "Q"
              byte $1E,$22,$22,$1E,$0A,$12,$22,$00  '  "R"
              byte $1C,$22,$02,$1C,$20,$22,$1C,$00  '  "S"
              byte $3E,$08,$08,$08,$08,$08,$08,$00  '  "T"
              byte $22,$22,$22,$22,$22,$22,$1C,$00  '  "U"
              byte $22,$22,$22,$14,$14,$08,$08,$00  '  "V"
              byte $22,$22,$22,$2A,$2A,$2A,$14,$00  '  "W"
              byte $22,$22,$14,$08,$14,$22,$22,$00  '  "X"
              byte $22,$22,$14,$08,$08,$08,$08,$00  '  "Y"
              byte $3E,$20,$10,$08,$04,$02,$3E,$00  '  "Z"
              byte $3E,$06,$06,$06,$06,$06,$3E,$00  '  "["
              byte $02,$02,$04,$08,$10,$20,$20,$00  '  "\"
              byte $3E,$30,$30,$30,$30,$30,$3E,$00  '  "]"
              byte $00,$00,$08,$14,$22,$00,$00,$00  '  "^"
              byte $00,$00,$00,$00,$00,$00,$00,$7F  '  "_"
              byte $10,$08,$18,$00,$00,$00,$00,$00  '  "`"
              byte $00,$00,$1C,$20,$3C,$22,$3C,$00  '  "a"
              byte $02,$02,$1E,$22,$22,$22,$1E,$00  '  "b"
              byte $00,$00,$3C,$02,$02,$02,$3C,$00  '  "c"
              byte $20,$20,$3C,$22,$22,$22,$3C,$00  '  "d"
              byte $00,$00,$1C,$22,$3E,$02,$3C,$00  '  "e"
              byte $18,$24,$04,$1E,$04,$04,$04,$00  '  "f"
              byte $00,$00,$1C,$22,$22,$3C,$20,$1C  '  "g"
              byte $02,$02,$1E,$22,$22,$22,$22,$00  '  "h"
              byte $08,$00,$0C,$08,$08,$08,$1C,$00  '  "i"
              byte $10,$00,$18,$10,$10,$10,$12,$0C  '  "j"
              byte $02,$02,$22,$12,$0C,$12,$22,$00  '  "k"
              byte $0C,$08,$08,$08,$08,$08,$1C,$00  '  "l"
              byte $00,$00,$36,$2A,$2A,$2A,$22,$00  '  "m"
              byte $00,$00,$1E,$22,$22,$22,$22,$00  '  "n"
              byte $00,$00,$1C,$22,$22,$22,$1C,$00  '  "o"
              byte $00,$00,$1E,$22,$22,$1E,$02,$02  '  "p"
              byte $00,$00,$3C,$22,$22,$3C,$20,$20  '  "q"
              byte $00,$00,$3A,$06,$02,$02,$02,$00  '  "r"
              byte $00,$00,$3C,$02,$1C,$20,$1E,$00  '  "s"
              byte $04,$04,$1E,$04,$04,$24,$18,$00  '  "t"
              byte $00,$00,$22,$22,$22,$32,$2C,$00  '  "u"
              byte $00,$00,$22,$22,$22,$14,$08,$00  '  "v"
              byte $00,$00,$22,$22,$2A,$2A,$36,$00  '  "w"
              byte $00,$00,$22,$14,$08,$14,$22,$00  '  "x"
              byte $00,$00,$22,$22,$22,$3C,$20,$1C  '  "y"
              byte $00,$00,$3E,$10,$08,$04,$3E,$00  '  "z"
              byte $38,$0C,$0C,$06,$0C,$0C,$38,$00  '  "{"
              byte $08,$08,$08,$08,$08,$08,$08,$08  '  "|"
              byte $0E,$18,$18,$30,$18,$18,$0E,$00  '  "}"
              byte $00,$2C,$1A,$00,$00,$00,$00,$00  '  "~"
              byte $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F   '  --


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