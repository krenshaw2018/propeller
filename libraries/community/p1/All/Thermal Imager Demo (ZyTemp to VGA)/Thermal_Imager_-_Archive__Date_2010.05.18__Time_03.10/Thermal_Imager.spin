{{      
┌──────────────────────────────────────────┐
│ IR Thermal Imager v1.0                   │
│ Author: Pat Daderko (DogP)               │               
│ Copyright (c) 2010                       │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

This demo combines reading temperatures with a ZyTemp (http://www.zytemp.com/) infrared thermometer with a VGA
bitmap display, creating a thermal raster image.  The image must be manually scanned, and with readings at a
rate of about 1.4Hz, it can take a while to create a full image.  This was tested with a ZyTemp TN203 (6:1
distance to spot, plus laser), rebranded as CEN-TECH #93984 from Harbor Freight.  It should work with any ZyTemp
Infrared Thermometer which communicates using the same protocol (such as the commonly found TN105i2).

These modules communicate using an SPI-like protocol.  The thermometer must be the Master though, so I modified
the SPI engine to support Slave operation (and included it with this demo).  The pins are accessible by opening
the case of the thermometer.  There's a 0.1" header at the bottom of the PCB with labels.

The pins are labeled:
A: Action
G: Ground
C: Clock      
D: Data
V: Vdd

This demo connects Clock to P0, Data to P1, Action to P2, and of course Ground to Vss.

To start an image, press and hold the Scan button and begin moving the thermometer horizontally at a steady pace.
As temperature readings are read, a white square corresponding to the current pixel is drawn.  After scanning a
line of the image, let go of the button.  Press and hold again to begin scanning the next line.  Repeat this until
you have the entire image scanned (maximum of 64 horizontal pixels by 48 vertical pixels).  When you're done,
single-click the Scan button.  This will draw the image to the screen, auto-scaling the image size and colors
corresponding to the temperatures in the image.  A scale is drawn on the side to show the colors for relative
temperatures.  The serial port is also used to output debug messages, such as each temperature read, and at the
end of the image, min/max temp and image size/scale.  

The image quality depends mostly on how steady the image is scanned, as well as distance to spot ratio of the
thermometer and the distance to the object being scanned.  Mounting the thermometer on an XY track controlled by
the Propeller would probably create the best image.  If you want software control of the Scan button, you can pull
the Action pin down on the Propeller.

This demo is based on my ZyTemp IR Thermometer Demo (based on Beau Schwabe's SPI Spin Demo), as well as Andy
Schenk's VGA 128x96 Bitmap Demo.  For more details on the ZyTemp thermometer, see the ZyTemp demo.  This imager
could also be modified to work with other IR thermometers, such as All Sun (which I've also written a demo for),
or for the Melexis module, available from Parallax. 
}}

CON
    _clkmode  = xtal1 + pll16x                           
    _xinfreq  = 5_000_000

    VGA_BPIN  = 16
    BMSIZE    = 12288

    MASTER    = 0
    SLAVE     = 1

    NUMCOLORS = 20 'number of false colors

OBJ
SPI     :       "SPI_Spin"                              ''The Standalone SPI Spin engine
Ser     :       "FullDuplexSerial"                      ''Used in this DEMO for Debug
VGA     :       "vga_128x96_Bitmap"                     ''For VGA display

VAR
LONG sixteenths[16]
LONG sync
BYTE pixels[BMSIZE]
BYTE falsecolor[NUMCOLORS]
WORD temp_reading[64*48]  
    
PUB Thermal_Imager|DQ,CLK,Start,ClockDelay,ClockState,Type,Data,Temp,i,j,k,l,curr_pixel,min_temp,max_temp,color_step,pixel_color,max_height,max_width,scale,scale2,draw_image

''Serial communication Setup
  Ser.start(31, 30, 0, 9600)  '' Initialize serial communication to the PC through the USB connector
                                '' To view Serial data on the PC use the Parallax Serial Terminal (PST) program.
''SPI Setup
  ClockDelay:=15
  ClockState:=1
  SPI.start(ClockDelay, ClockState) '' Initialize SPI Engine with Clock Delay of 15us and Clock State of 1
   
  SPI.setMasterSlave(SLAVE)
   

''Pin Setup
  DQ    := 1                  '' Set Data Pin
  CLK   := 0                  '' Set Clock Pin
  Start := 2                  '' Set Start Pin
  dira[Start]~                '' Make Start Pin input to read when pressed (can also drive start pin, though you should disable the module's button)

''start vga
  vga.start(VGA_BPIN, @pixels, @sync)

''make list of 20 false colors for temperature
  j:=0
  falsecolor[j++]:=%%000_0
  falsecolor[j++]:=%%001_0
  falsecolor[j++]:=%%002_0
  falsecolor[j++]:=%%003_0
  falsecolor[j++]:=%%013_0
  falsecolor[j++]:=%%023_0
  falsecolor[j++]:=%%033_0
  falsecolor[j++]:=%%032_0
  falsecolor[j++]:=%%031_0
  falsecolor[j++]:=%%030_0
  falsecolor[j++]:=%%130_0
  falsecolor[j++]:=%%230_0
  falsecolor[j++]:=%%330_0
  falsecolor[j++]:=%%320_0
  falsecolor[j++]:=%%310_0
  falsecolor[j++]:=%%300_0
  falsecolor[j++]:=%%200_0
  falsecolor[j++]:=%%211_0
  falsecolor[j++]:=%%322_0
  falsecolor[j++]:=%%333_0

''clear screen
  repeat i from 0 to BMSIZE - 1
    pixels[i] := %%000_0        'black

''Make LUT for sixteenths
  sixteenths[0]:=string("0000")
  sixteenths[1]:=string("0625")
  sixteenths[2]:=string("1250")
  sixteenths[3]:=string("1875")
  sixteenths[4]:=string("2500")
  sixteenths[5]:=string("3125")
  sixteenths[6]:=string("3750")
  sixteenths[7]:=string("4375")
  sixteenths[8]:=string("5000")
  sixteenths[9]:=string("5625")
  sixteenths[10]:=string("6250")
  sixteenths[11]:=string("6875")
  sixteenths[12]:=string("7500")
  sixteenths[13]:=string("8125")
  sixteenths[14]:=string("8750")
  sixteenths[15]:=string("9375")

''initialize variables
  curr_pixel:=0
  draw_image:=2
  max_width:=1
  scale:=1
  min_temp:=$FFFF
  max_temp:=0

  repeat
    waitpne(|<Start, |<Start, 0) ''only read when button is pressed
    Type := SPI.SHIFTIN(DQ, CLK, SPI#MSBPOST, 8)  '' read the message type
    Data := SPI.SHIFTIN(DQ, CLK, SPI#MSBPOST, 32)  '' read the message data

    if draw_image==2 'clear image
      repeat i from 0 to BMSIZE - 1
        pixels[i] := %%000_0 'black 
      repeat i from 0 to (64*48) - 1
        temp_reading[i]:=0
      draw_image:=0
   
    if Type == $4C ''Object Temp
      if (Data&$FF == $0D) AND (Type+(Data>>16)+(Data>>24))&$FF==((Data>>8)&$FF) ''checksum good
        Ser.str(string("Object Temp:"))
        Temp := ((Data>>16)-((273<<4)+2)) ''(Value/16)-273.15 (actually 273.125 in calculation)
        Ser.dec(Temp>>4) ''output whole degrees (in C)
        Ser.tx(".")
        Ser.str(@BYTE[sixteenths[(Temp&$F)]]) ''output fraction degrees (in C)
        Ser.str(string("°C"))
        Ser.tx(13)

        'record min/max temp (for temperature scaling)
        temp_reading[curr_pixel]:=Temp
        if Temp<min_temp
          min_temp:=Temp
        if Temp>max_temp
          max_temp:=Temp

        'draw white block corresponding to current pixel
        pixels[3072+((curr_pixel<<1)&$F80)+32+(curr_pixel&63)]:=%%333_0
        if (curr_pixel&63)<63
          curr_pixel++

    elseif Type == $66 ''Ambient Temp
      if (Data&$FF == $0D) AND (Type+(Data>>16)+(Data>>24))&$FF==((Data>>8)&$FF) ''checksum good
        Ser.str(string("Ambient Temp:"))
        Temp := ((Data>>16)-((273<<4)+2)) ''(Value/16)-273.15 (actually 273.125 in calculation)
        Ser.dec(Temp>>4) ''output whole degrees (in C)
        Ser.tx(".")
        Ser.str(@BYTE[sixteenths[(Temp&$F)]]) ''output fraction degrees (in C)
        Ser.str(string("°C"))
        Ser.tx(13)

    if ina[start] 'if Scan button released
      'record maximum image width (for image size scaling)
      if (curr_pixel&63)>max_width
        max_width:=curr_pixel&63
        
      if (curr_pixel&63)=<1 'single clicked button to signal end
        draw_image:=1
      else 'not single clicked, go to next line
        if curr_pixel=<2944 'not at end of image yet
          curr_pixel:=(curr_pixel+64)&$FC0
        else 'too many lines, done
          draw_image:=1
      
    ''image drawing section
    if draw_image
      ''output debug stuff
      Ser.str(string("Drawing image"))
      Ser.tx(13)

      Ser.str(string("Min:"))
      Ser.dec(min_temp>>4) ''output whole degrees (in C)
      Ser.tx(".")
      Ser.str(@BYTE[sixteenths[(min_temp&$F)]]) ''output fraction degrees (in C)
      Ser.str(string("°C"))
      Ser.tx(13)

      Ser.str(string("Max:"))
      Ser.dec(max_temp>>4) ''output whole degrees (in C)
      Ser.tx(".")
      Ser.str(@BYTE[sixteenths[(max_temp&$F)]]) ''output fraction degrees (in C)
      Ser.str(string("°C"))
      Ser.tx(13)

      Ser.str(string("Image Width:"))
      Ser.dec(max_width)
      Ser.tx(13)

      max_height:=curr_pixel>>6
      Ser.str(string("Image Height:"))
      Ser.dec(max_height)
      Ser.tx(13)

      scale:=64/max_width
      scale2:=48/max_height
      if (scale2<scale)
        scale:=scale2
      Ser.str(string("Image Scale:"))
      Ser.dec(scale)
      Ser.tx(13)

      pixels[3072+32+(max_height<<7)] := %%000_0 'overwrite last stray block from end click

      'get color step size (<<6 before div to give more resolution)       
      color_step:=((max_temp-min_temp)<<6)/NUMCOLORS
      if color_step<1 'prevent div by 0
        color_step:=1

      'draw scale on side of image
      repeat i from 0 to NUMCOLORS-1
        pixels[3072+110+(NUMCOLORS-i)<<7] := falsecolor[i]

      'loop through readings and draw bitmap
      repeat i from 0 to max_height-1 'height
        repeat j from 0 to max_width-1 'width
          if temp_reading>0 'actual reading
            pixel_color:=((temp_reading[(i<<6)+j]-min_temp)<<6)/color_step 'get pixel color of reading
            if pixel_color<NUMCOLORS 'if on scale set to corresponding color 
              pixel_color := falsecolor[pixel_color]
            else 'if too large, draw as hottest (possible due to loss of precision) 
              pixel_color := falsecolor[NUMCOLORS-1]
          else 'unsampled pixel, draw as coldest 
            pixel_color := falsecolor[0]

          'draw scaled image to screen buffer
          repeat k from 0 to scale
            repeat l from 0 to scale 
              pixels[3072+32+(((i*scale)+k)<<7)+((j*scale)+l)] := pixel_color

      'reset variables
      curr_pixel:=0
      draw_image:=2 'tell it to clear on next run
      max_width:=1
      scale:=1
      min_temp:=$FFFF
      max_temp:=0

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