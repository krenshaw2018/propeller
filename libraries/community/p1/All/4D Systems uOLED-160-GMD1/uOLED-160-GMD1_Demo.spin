{{
┌────────────────────────────┐
│ µOLED-160-GMD1 Demo Object │
├────────────────────────────┴─────────────────┐
│  Width      : 160 Pixels                     │
│  Height     : 128 Pixels                     │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│ Copyright (c) 2007 Steve McManus         │               
│     See end of file for terms of use.    │               
└──────────────────────────────────────────┘
A program to demonstrate the capabilities of the 4D Systems uOLED-160-GMD1 display module.

The GMD1 models from 4D Systems utilize a custom-built embedded processor (GOLDELOX-MD1) to provide a
simple serial interface to the OLED display module. A downloadable PmmC (Personality module micro-Code)
provides custom software for each display module where the GOLDELOX-MD1 is used.

The command set for the uOLED-160_GMD1 differs from the older uOLED modules (uOLED-96-xMB, uOLED-128-xMB and
uOLED-128-xMB) from 4D Systems. The older modules utilized flash memory for storage of images, text, cammands
and command scripts. The newer GMD1 and PMD2 models have a built-in uSD card adapter used for this purpose.

This demo exercises most of the available commands for the device. If you do not have a uSD card inserted,  
comment out the calls for all xxxxx_2_uSD and xxxxx_FROM_uSD methods and set the SD_Demo flag to 0
in the "Demo" Public Method. Also, comment out the CLEAR_SECTORS call at the beginning of the Demo methode.
This methode clears the first 200 sectors (used by the demo) of the uSD card, if one is present and is called
only once during execution.  

SETUP and SHUTDOWN methods are required for proper operation. The other calls in the Demo method may be
commented out or arranged to suit.

The SHUTDOWN method provides a 5 second delay after the Display PowerOff cycle before the demo restarts. This permits
the user to power off the Propeller system without the risk of damaging the display by removing power while the
display electronics are powered on (see the uOLED-160-GMD1 documentation for details). 

All images are my original work and may be used for any non-commercial purpose.

Steve McManus    smcmanus@att.net

}}
CON
  _CLKMODE      = XTAL1 + PLL16X                        
  _XINFREQ      = 5_000_000

VAR
  long SAddr
  long MAddr
  word Type
  word HW
  word SW
  word DevX
  word DevY
  word SD_Demo
  byte uSD_Sector[512]
  
OBJ
  OLED  : "uOLED-160-GMD1"
  DELAY : "Clock"  

PUB Demo

  OLED.INIT

  SD_Demo := 1                  'Set to 0 if xxx_2_uSD and xxx_From_uSD routines are commented out                        

  CLEAR_SECTORS                 'Clears the first 240 sectors on the uSD card
   
  REPEAT
    SETUP
    
    TEXTSIZE
    BIGTEXT
    STOPSIGN
    WIREFRAME
    SOLID
    STRING_ART
    WALKER
    WITCH
    WITCH_2_uSD
    STRIPCHART
    STRIPCHART_2_uSD
    PUTPIXEL
    BUTTONS
    FASTSCROLL
    MONITOR
    MONITOR_2_uSD
    DEVICEINFO
    MONITOR_FROM_uSD
    STRIPCHART_FROM_uSD
    WITCH_FROM_uSD
    PART_SCREENS_FROM_uSD
    FAST_IMAGES_FROM_uSD
    CONTRAST
      
    SHUTDOWN
    
    
  
PUB SETUP
  OLED.ERASE
  OLED.BACKGROUND(0,0,0)
  OLED.CONTRAST(12)

PUB CLEAR_SECTORS | Temp
  'Clears a range of sectors on the uSD card
  REPEAT Temp from 0 to 511                             'Clear uSD buffer
    uSD_Sector[Temp] := $00
    
  OLED.OPAQUE
  OLED.FTEXT(4,2,2, 255,255,255, string("Clearing "), 0)
  OLED.FTEXT(4,3,2, 255,255,255, string(" Sector  "), 0)
     
  REPEAT Temp from 0 to 239
    SAddr := Temp
    OLED.WRITE_SECTOR(@SAddr, @uSD_Sector)
    OLED.UTEXT(30,55,2, 0,240,0, 3,3, SAddr, 1)

  DELAY.PauseSec(1)
  SETUP
  
PUB TEXTSIZE


  OLED.FTEXT(0,1, 2, 255,255,255, string("Font 0  5x7"),0)
  OLED.FTEXT(0,4, 0, 255,255,0, string(" ! @ # $ % ^ & * ( ) _ + - = 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z { } [ ] | \ ; : ' < > ? , . /"),0)
  DELAY.PauseSec(5)
  OLED.ERASE
   
  OLED.FTEXT(0,1, 2, 255,255,255, string("Font 1  8x8"),0)
  OLED.FTEXT(0,4, 1, 0,255,255, string(" ! @ # $ % ^ & * ( ) _ + - = 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z { } [ ] | \ ; : ' < > ? , . /"),0)
  DELAY.PauseSec(5)
  OLED.ERASE
   
  OLED.FTEXT(0,1, 2, 255,255,255, string("Font 2  8x12"),0)
  OLED.FTEXT(0,3, 2, 255,255,255, string(" ! @ # $ % ^ & * ( ) _ + - = 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z { } [ ] | \ ; : ' < > ? , . /"),0)
  DELAY.PauseSec(5)                                          
  OLED.ERASE
   
  OLED.FTEXT(0,1, 0, 200,200,200, string("This is just a lot of text to demonstrate text wrap on the screen"),0)
  DELAY.PauseSec(3)
  OLED.FTEXT(0,6, 1, 200,200,0, string("You can go small as above, or you can go"),0)
  DELAY.PauseSec(2)
  OLED.UTEXT(30,90, 2, 255,255,0, 3,3,string("BIG"),0)
  DELAY.PauseSec(3)
  SETUP

PUB BIGTEXT | Temp
  OLED.FONT_SIZE(1)
  OLED.OPAQUE
  REPEAT Temp from 1 to 3
    OLED.UCHAR("T", 4,4, 200,200,0, 14,14)
    DELAY.PauseMSec(200)
    OLED.UCHAR("E", 4,4, 200,200,0, 14,14)
    DELAY.PauseMSec(200)
    OLED.UCHAR("S", 4,4, 200,200,0, 14,14)
    DELAY.PauseMSec(200)
    OLED.UCHAR("T", 4,4, 200,200,0, 14,14)
    DELAY.PauseMSec(200)
    OLED.ERASE
    DELAY.PauseSec(1)
    OLED.UTEXT( 30,5, 1, 200,200,200, 2,2, string("Temp"),0)
    
    CASE Temp
      1: OLED.UTEXT(5,45, 2, 0,250,0, 3,3, string("125 C"),0)
      
      2: OLED.UTEXT(5,45, 2, 200,250 ,0, 3,3, string("248 C"),0)
      
      3: OLED.UTEXT(5,45, 2, 250,0,0, 3,3, string("327 C"),0)
           
    DELAY.PauseSec(3)
    OLED.ERASE
    
  OLED.ERASE
  OLED.UCHAR("S", 4,4, 120,0,0, 14,14)
  DELAY.PauseMSec(200)
  OLED.UCHAR("T", 4,4, 120,0,0, 14,14)
  DELAY.PauseMSec(200)
  OLED.UCHAR("O", 4,4, 120,0,0, 14,14)
  DELAY.PauseMSec(200)
  OLED.UCHAR("P", 4,4, 120,0,0, 14,14)
  DELAY.PauseMSec(200)
  OLED.ERASE
  DELAY.PauseSec(1)
  SETUP
        
PUB STOPSIGN
  OLED.POLYGON_6(35,10, 0,62, 35,116, 85,116, 116,62, 85,10, 155,0,0)
  OLED.TRANSPARENT
  OLED.UTEXT(12,48, 1, 120,0,0, 3,4, string("STOP"),0)
   
  OLED.SOLID
  OLED.CIRCLE(60,108,4, 200,0,0)
  OLED.RECTANGLE(58,78, 62,108, 200,0,0)
  OLED.RECTANGLE(59,75, 61,94, 0,0,0)
  OLED.CIRCLE(60,78,2, 200,0,0)
   
  OLED.LINE(60,98, 50,103, 200,0,0)
  OLED.LINE(60,98, 70,103, 200,0,0)
   
  OLED.LINE(50,103, 40,98, 200,0,0)
  OLED.LINE(70,103, 80,98, 200,0,0)
   
  OLED.LINE(40,98, 35,103, 200,0,0)
  OLED.LINE(80,98, 85,103, 200,0,0)
   
  DELAY.PauseMSec(500)
   
  REPEAT 3
    OLED.UTEXT(12,48, 1, 0,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(200)
    OLED.UTEXT(12,48, 1, 120,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    
 
  DELAY.PauseSec(1)
  OLED.SCROLL_CONTROL (0,5)
  OLED.SCROLL_ENABLE (1)
  REPEAT 4
    OLED.UTEXT(12,48, 1, 0,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    OLED.UTEXT(12,48, 1, 120,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    
  OLED.SCROLL_CONTROL (1,5)
  OLED.SCROLL_ENABLE (1)
  REPEAT 4
    OLED.UTEXT(12,48, 1, 0,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    OLED.UTEXT(12,48, 1, 120,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    
  OLED.SCROLL_CONTROL (0,5)
  OLED.SCROLL_ENABLE (1)
  REPEAT 4
    OLED.UTEXT(12,48, 1, 0,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    OLED.UTEXT(12,48, 1, 120,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)

  OLED.SCROLL_CONTROL (1,5)
  OLED.SCROLL_ENABLE (1)
  REPEAT 4
    OLED.UTEXT(12,48, 1, 0,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
    OLED.UTEXT(12,48, 1, 120,0,0, 3,4, string("STOP"),0)
    DELAY.PauseMSec(500)
     
  OLED.SCROLL_CONTROL (0,0)
  OLED.SCROLL_ENABLE (0)
  DELAY.PauseSec(3)
     
  SETUP
    
PUB WIREFRAME
  OLED.FTEXT(3,0, 0, 255,255,255, string("Wire Frame  Pen 1"),0)
  OLED.WIRE 
   
  OLED.TRIANGLE(40,20, 20,100, 110,80, 0,250,0)
  DELAY.PauseSec(2)
  OLED.CIRCLE(60,50,20, 250,0,0)
  DELAY.PauseSec(2)
  OLED.RECTANGLE(80,20, 120,120, 250,250,0)
  DELAY.PauseSec(2)
  OLED.POLYGON_6(70,20, 20,60, 40,75, 20,120, 110,100, 70,60, 0,0,255)
  DELAY.PauseSec(3)
   
  SETUP
    
PUB SOLID
  OLED.SOLID
  OLED.FTEXT(3,0, 0, 255,255,255,string("Solid  Pen 0"),0)
   
  OLED.TRIANGLE(40,20, 20,100, 110,80, 0,250,0)
  DELAY.PauseSec(2)
  OLED.CIRCLE(60,50,20, 250,0,0)
  DELAY.PauseSec(2)
  OLED.RECTANGLE(80,20, 120,120, 250,250,0)
  DELAY.PauseSec(2)
   
  SETUP

PUB STRING_ART |Temp,p1,p2,p3,p4,p5,p6

  OLED.PUT_PIXEL(63,63, 0,250,0)
  DELAY.PauseSec(2)
  
  p1 := 62
  p3 := 64
  REPEAT 40
    OLED.LINE(p1--,63, p3++,63, 0,250,0)
    DELAY.PauseMSec(30)

  DELAY.PauseMSec(700)

  p4 := 63
  REPEAT 35
    OLED.LINE(63,63, p3,p4++, 0,0,0)
    OLED.LINE(63,63, p3,p4, 0,250,0)
    DELAY.PauseMSec(30)

  DELAY.PauseMSec(700)

  p2 := 63
  REPEAT 25
    OLED.LINE(63,63, p1,p2++, 0,0,0)
    OLED.LINE(63,63, p1,p2, 0,250,0)
    DELAY.PauseMSec(30)

  DELAY.PauseMSec(700)
  
  p5 := p3 -1
  REPEAT until p5 == p1
    OLED.LINE(p5--,p4, p3,p4, 0,250,0)
    DELAY.PauseMSec(30)

  DELAY.PauseMSec(700)
  
  p6 := p4
  REPEAT until p6 == p2
    OLED.Line(p3,p4, p5,p6--, 0,0,0)
    OLED.Line(p3,p4, p5,p6, 0,250,0)
    DELAY.PauseMSec(40)

  'OLED.POLYGON_3(p1,p2, p3,p4, p5,p6, 0,0,0)
  DELAY.PauseMSec(700)
    
  OLED.WIRE
  p1 := 63
  p2 := 63
  REPEAT until p6 == 63
    OLED.POLYGON_3(p1++,p2, p5,p6--, p3--,p4, 0,0,0)
    OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
    DELAY.PauseMSec(30)

  DELAY.PauseMSec(700)
  
  REPEAT 5
    OLED.POLYGON_3(p1,p2--, p5,p6, p3,p4, 0,0,0)
    OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
    DELAY.PauseMSec(30)       

  DELAY.PauseMSec(700)

  REPEAT 3
     
    REPEAT 10
      OLED.POLYGON_3(p1,p2, p5,p6--, p3,p4, 0,0,0)
      OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
      DELAY.PauseMSec(30)
     
    DELAY.PauseMSec(700)
     
    REPEAT 10
      OLED.POLYGON_3(p1,p2--, p5,p6, p3,p4, 0,0,0)
      OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
      DELAY.PauseMSec(30)       
     
    DELAY.PauseMSec(700)

  REPEAT 5
      OLED.POLYGON_3(p1,p2, p5,p6--, p3,p4, 0,0,0)
      OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
      DELAY.PauseMSec(30)
     
  DELAY.PauseMSec(700)

  DELAY.PauseSec(2)

  OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 250,0,0)
  OLED.FTEXT(3,0, 2, 250,0,0, string("Catch"),0)
  DELAY.PauseMSec(500)
  OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 250,0,0)
  OLED.FTEXT(9,0, 2, 250,0,0, string("UP!"),0)
  DELAY.PauseMSec(300)
  OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
  DELAY.PauseSec(2)

  REPEAT 20
    OLED.POLYGON_3(p1,p2, p5,p6, p3,p4--, 0,0,0)
      OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
      DELAY.PauseMSec(20)

  REPEAT 9
    OLED.POLYGON_3(p1,p2, p5,p6, p3--,p4--, 0,0,0)
      OLED.POLYGON_3(p1,p2, p5,p6, p3,p4, 0,250,0)
      DELAY.PauseMSec(20)

  DELAY.PauseMSec(200)

  OLED.FTEXT(3,0, 2, 250,0,0, string("          "),0)
  
  DELAY.PauseSec(4)

  SETUP

PUB WALKER | Temp,p1,p2,p3,p4,p5,p6, p7,p8,p9,p10,p11,p12
  
  p1 := 0
  p2 := 50

  p3 := 0
  p4 := 90

  p5 := 20
  p6 := 90

  p7 := 70
  p8 := 90

  p9 := 90
  p10 := 90

  p11 := 90
  p12 := 50

  
  OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
  DELAY.PauseSec(3)

  REPEAT 35
    OLED.POLYGON_6(p1,p2--, p3,p4, p5,p6--, p7,p8--, p9,p10, p11,p12--, 0,0,0)
    OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
    DELAY.PauseMSec(40)

  DELAY.PauseMSec(1000)

  REPEAT 11

    REPEAT 15
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10--, p11,p12, 0,0,0)
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
      DELAY.PauseMSec(5)
     
    REPEAT 15
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9++,p10, p11,p12, 0,0,0)
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
      DELAY.PauseMSec(5)
     
    REPEAT 15
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10++, p11,p12, 0,0,0)
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
      DELAY.PauseMSec(5)
     
    REPEAT 15
      OLED.POLYGON_6(p1++,p2, p3,p4--, p5++,p6, p7++,p8, p9,p10, p11++,p12, 0,0,0)
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
      DELAY.PauseMSec(5)
     
    REPEAT 15
      OLED.POLYGON_6(p1,p2, p3++,p4, p5,p6, p7,p8, p9,p10, p11,p12, 0,0,0)
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
      DELAY.PauseMSec(5)
     
    REPEAT 15
      OLED.POLYGON_6(p1,p2, p3,p4++, p5,p6, p7,p8, p9,p10, p11,p12, 0,0,0)
      OLED.POLYGON_6(p1,p2, p3,p4, p5,p6, p7,p8, p9,p10, p11,p12, 100,100,0)
      DELAY.PauseMSec(5)


  p1 := 160
  P2 := 25

  DELAY.PauseSec(1)
  OLED.WIRE
  'OLED.CIRCLE(p1--,p2, 5, 100,100,0)

  REPEAT 45
    OLED.CIRCLE(p1--,p2++, 5, 0,0,0)
    p2++
    OLED.CIRCLE(p1,p2, 5, 100,100,0)
    DELAY.PauseMSec(20)

  OLED.SOLID
  OLED.CIRCLE(p1,p2, 5, 100,100,0)
    
  DELAY.PauseSec(4)
  

  SETUP
PUB WITCH | Temp
  OLED.RECTANGLE(0,0, 159,70, 0,0,250)                 'Sky
  OLED.RECTANGLE(0,71, 159,127, 0,0,125)               'Water

  OLED.CIRCLE(35,20,10, 250,250,0)                      'Sun

  OLED.Line( 78,90, 107,90, 0,0,0)                      'Hat
  OLED.Line( 78,91, 107,91, 0,0,0)
  OLED.Line( 78,92, 107,92, 0,0,0)
  OLED.TRIANGLE(92,58, 83,90, 102,90, 0,0,0)
  
  Temp := 200
  OLED.TRIANGLE(0,55, 0,70, 5,55, 150,150,150)          'Ship
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,75, 10,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,80, 15,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,85, 20,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,90, 25,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,95, 35,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  
  OLED.TRIANGLE(0,55, 0,95, 40,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,95, 45,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,95, 50,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,95, 55,55, 150,150,150)
  DELAY.PauseMSec(Temp)
  OLED.TRIANGLE(0,55, 0,95, 60,55, 150,150,150)
  DELAY.PauseMSec(Temp)

  DELAY.PauseSec(4)                                     'Answer
  OLED.TRANSPARENT
  OLED.FTEXT(2,13,0, 255,255,255, string("A ship arriving too late to save a drowning witch"),0)
  DELAY.PauseSec(6)
  
  IF not SD_Demo
    SETUP

PUB WITCH_2_uSD
  'Copy the previous screen, "WITCH" to the uSD card at Sector 0 (80 Sectors)
  SAddr := 0
   OLED.SCREEN_2_uSD(0,0, 159,128, @SAddr)
   OLED.OPAQUE
   OLED.FTEXT(1,5, 2, 255,255,255, string("Screen Copied"),0)
   DELAY.PauseSec(3)
   SETUP
     
PUB STRIPCHART
    
  OLED.RECTANGLE(0,0, 159,15, 100,100,100)
  OLED.RECTANGLE(0,110, 159,127, 100,100,100) 
   
  OLED.LINE( 7,113, 7,123, 0,0,0)
  OLED.LINE( 15,113, 15,123, 0,0,0)
  OLED.LINE( 23,113, 23,123, 0,0,0)
  OLED.LINE( 31,113, 31,123, 0,0,0)
  OLED.LINE( 39,113, 39,123, 0,0,0)
  OLED.LINE( 47,113, 47,123, 0,0,0)
  OLED.LINE( 55,113, 55,123, 0,0,0)
  OLED.LINE( 63,113, 63,123, 0,0,0)
  OLED.LINE( 71,113, 71,123, 0,0,0)
  OLED.LINE( 79,113, 79,123, 0,0,0)
  OLED.LINE( 87,113, 87,123, 0,0,0)
  OLED.LINE( 95,113, 95,123, 0,0,0)
  OLED.LINE( 103,113, 103,123, 0,0,0)
  OLED.LINE( 111,113, 111,123, 0,0,0)
  OLED.LINE( 119,113, 119,123, 0,0,0)
  OLED.LINE( 127,113, 127,123, 0,0,0)
  OLED.LINE( 135,113, 135,123, 0,0,0)
  OLED.LINE( 143,113, 143,123, 0,0,0)
  OLED.LINE( 151,113, 151,123, 0,0,0)
  OLED.LINE( 159,113, 159,123, 0,0,0)
   
  OLED.LINE( 0,33, 159,33, 250,0,0)
  OLED.LINE( 0,63, 159,63, 200,200,200)
  OLED.LINE( 0,93, 159,93, 250,0,0)
   
  DELAY.PauseSec(1)
   
   
  OLED.LINE( 0,63, 7,40, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 7,40, 15,80, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 15,80, 23,25, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 23,25, 31,50, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 31,50, 39,65, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 39,65, 47,90, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 47,90, 55,40, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 55,40, 63,90, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 63,90, 71,30, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 71,30, 79,88, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 79,88, 87,60, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 87,60, 95,20, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 95,20, 103,106, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 103,106, 111,35, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 111,35, 119,88, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 119,88, 127,63, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 127,63, 135,45, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 135,45, 143,30, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 143,30, 151,94, 0,250,0)
  DELAY.PauseMSec(100)
  OLED.LINE( 151,94, 159,63, 0,250,0)
    
  OLED.SCROLL_CONTROL (0,5)
  OLED.SCROLL_ENABLE (1)
  DELAY.PauseMSec(11800)
  OLED.SCROLL_CONTROL (0,0)
  OLED.SCROLL_ENABLE (0)
  DELAY.PauseSec(2)
    
  IF not SD_Demo
    SETUP

PUB STRIPCHART_2_uSD
  'Copy the previous screen, "STRIPCHART" to the uSD card at Sector 80 (80 Sectors)
  SAddr := 80
   OLED.SCREEN_2_uSD(0,0, 159,128, @SAddr)
   
   OLED.OPAQUE
   OLED.FTEXT(1,5, 2, 255,255,255, string("Screen Copied"),0)
   DELAY.PauseSec(3)
   SETUP
   
PUB PUTPIXEL | Temp
    
  OLED.BACKGROUND(120,0,0)
   
  OLED.FTEXT(1,13, 1, 255,255,255, string("Put Pixel"),0)
  DELAY.PauseSec(1)
   
  REPEAT Temp from 10 to 80 step 2                      'Down
   OLED.PUT_PIXEL(10,Temp, 255,255,255)
   DELAY.PauseMSec(20)
   
  REPEAT Temp from 10 to 80 step 2                      'Right
   OLED.PUT_PIXEL(Temp,80, 255,255,255)
   DELAY.PauseMSec(20)
   
  REPEAT Temp from 80 to 10 step 2                      'Up
   OLED.PUT_PIXEL(80,Temp, 255,255,255)
   DELAY.PauseMSec(20)

  REPEAT Temp from 80 to 10 step 2                      'Left
   OLED.PUT_PIXEL(Temp,10, 255,255,255)
   DELAY.PauseMSec(20)

  DELAY.PauseSec(2)
   
  SETUP
    
    
PUB BUTTONS
  OLED.BACKGROUND(0,0,0)
  OLED.SOLID
  OLED.TRANSPARENT
  OLED.BUTTON(1, 5,16, 200,0,0, 0, 255,255,255, 1,1, string(" FIRST "))
  OLED.BUTTON(1, 30,42, 0,200,0, 1, 255,255,255, 1,1, string(" NEXT "))
  OLED.BUTTON(1, 5,70, 0,0,200, 2, 255,255,255, 2,2, string(" LAST "))
  DELAY.PauseSec(2)
   
  OLED.BUTTON(0, 5,16, 200,0,0, 0, 0,0,0, 1,1, string(" FIRST "))
  DELAY.PauseSec(2)
  OLED.BUTTON(0, 30,42, 0,200,0, 1, 0,0,0, 1,1, string(" NEXT "))
  DELAY.PauseSec(2)
  OLED.BUTTON(0, 5,70, 0,0,200, 2, 0,0,0, 2,2, string(" LAST "))
  DELAY.PauseSec(2)
  OLED.ERASE
  OLED.BACKGROUND(0,0,0)
  DELAY.PauseSec(1)
  SETUP
    
PUB FASTSCROLL | Temp
  Temp := 10
  REPEAT 35
    if Temp > 1
      OLED.BLOCK_COPY(0,60, Temp - 5,Temp - 5, 30,40)
    OLED.BUTTON(1,Temp,Temp, 0,100,100, 1, 200,0,0, 2,2, string("X"))
    Temp += 2
    DELAY.PauseMSec(5)
    
  DELAY.PauseSec(1)
   
  OLED.OPAQUE
  OLED.FTEXT(4,2, 1, 255,255,0, string("Count:"),0)

  OLED.SCROLL_CONTROL(1,7)
  OLED.SCROLL_ENABLE(1)
  DELAY.PauseSec(3)
  OLED.SCROLL_ENABLE(0)
  DELAY.PauseSec(1)
  
  REPEAT Temp from 0 to 256 step 25
    OLED.FTEXT(11,2, 1, 255,255,0, Temp,1)
    DELAY.PauseMSec(500)
    
  DELAY.PauseSec(2)
  SETUP
    
PUB MONITOR
  OLED.BACKGROUND(0,0,0)
  OLED.SOLID
  OLED.RECTANGLE(0,0, 159,127, 100,100,100)
  OLED.WIRE
  OLED.RECTANGLE(3,3, 159 - 4,124, 200,200,200)
  OLED.RECTANGLE(4,4, 159 - 4,123, 200,200,200)
  OLED.RECTANGLE(5,5, 159 - 5,122, 200,200,200)
  OLED.RECTANGLE(6,6, 159 - 6,121, 30,30,30)
   
  OLED.SOLID
  OLED.RECTANGLE(8,8, 91,39, 0,0,0)

  OLED.TRANSPARENT 
  OLED.UTEXT(9,45, 2, 0,0,0, 1,1, string("PULSE"),0)
  OLED.OPAQUE 
  OLED.UTEXT(56,45, 2, 250,250,0, 1,1, string("78"),0)
   
  OLED.LINE(10,30, 12,30, 0,250,0)
  OLED.LINE(12,30, 14,28, 0,250,0)
  OLED.LINE(14,28, 16,30, 0,250,0)
  OLED.LINE(16,30, 18,30, 0,250,0)
  OLED.LINE(18,30, 20,16, 0,250,0)
  OLED.LINE(20,16, 22,34, 0,250,0)
  OLED.LINE(22,34, 26,26, 0,250,0)
  OLED.LINE(26,26, 28,30, 0,250,0)
  OLED.LINE(28,30, 30,30, 0,250,0)
   
  OLED.LINE(30,30, 32,30, 0,250,0)
  OLED.LINE(32,30, 34,28, 0,250,0)
  OLED.LINE(34,28, 36,30, 0,250,0)
  OLED.LINE(36,30, 38,30, 0,250,0)
  OLED.LINE(38,30, 40,16, 0,250,0)
  OLED.LINE(40,16, 42,34, 0,250,0)
  OLED.LINE(42,34, 46,26, 0,250,0)
  OLED.LINE(46,26, 48,30, 0,250,0)
  OLED.LINE(48,30, 50,30, 0,250,0)
   
  OLED.LINE(50,30, 52,30, 0,250,0)
  OLED.LINE(52,30, 54,28, 0,250,0)
  OLED.LINE(54,28, 56,30, 0,250,0)
  OLED.LINE(56,30, 58,30, 0,250,0)
  OLED.LINE(58,30, 60,16, 0,250,0)
  OLED.LINE(60,16, 62,34, 0,250,0)
  OLED.LINE(62,34, 66,26, 0,250,0)
  OLED.LINE(66,26, 68,30, 0,250,0)
  OLED.LINE(68,30, 70,30, 0,250,0)
   
  OLED.LINE(70,30, 72,30, 0,250,0)
  OLED.LINE(72,30, 74,28, 0,250,0)
  OLED.LINE(74,28, 76,30, 0,250,0)
  OLED.LINE(76,30, 78,30, 0,250,0)
  OLED.LINE(78,30, 80,16, 0,250,0)
  OLED.LINE(80,16, 82,34, 0,250,0)
  OLED.LINE(82,34, 86,26, 0,250,0)
  OLED.LINE(86,26, 88,30, 0,250,0)
  OLED.LINE(88,30, 90,30, 0,250,0)
   
  OLED.RECTANGLE(8,58, 91,90, 0,0,0)
  OLED.TRANSPARENT 
  OLED.UTEXT(9,95, 2, 0,0,0, 1,1, string("RESP"),0)
  OLED.OPAQUE
  OLED.UTEXT(47,95, 2, 250,250,0, 1,1, string("20"),0)
   
  OLED.LINE(10,84, 14,66, 0,250,0)
  OLED.LINE(14,66, 18,84, 0,250,0)
  OLED.LINE(18,84, 22,66, 0,250,0)
  OLED.LINE(22,66, 26,84, 0,250,0)
  OLED.LINE(26,84, 30,66, 0,250,0)
   
  OLED.LINE(30,66, 34,84, 0,250,0)
  OLED.LINE(34,84, 38,66, 0,250,0)
  OLED.LINE(38,66, 42,84, 0,250,0)
  OLED.LINE(42,84, 46,66, 0,250,0)
  OLED.LINE(46,66, 50,84, 0,250,0)
   
  OLED.LINE(50,84, 54,66, 0,250,0)
  OLED.LINE(54,66, 58,84, 0,250,0)
  OLED.LINE(58,84, 62,66, 0,250,0)
  OLED.LINE(62,66, 66,84, 0,250,0)
  OLED.LINE(66,84, 70,66, 0,250,0)
   
  OLED.LINE(70,66, 74,84, 0,250,0)
  OLED.LINE(74,84, 78,66, 0,250,0)
  OLED.LINE(78,66, 82,84, 0,250,0)
  OLED.LINE(82,84, 86,66, 0,250,0)
  OLED.LINE(86,66, 90,84, 0,250,0)

  OLED.TRANSPARENT 
  OLED.BUTTON(1,68,100, 250,0,0, 1, 0,0,0, 1,1, string("RESET"))
   
  OLED.WIRE
  OLED.RECTANGLE(100,15, 110,75, 0,0,0)
  OLED.SOLID
  OLED.RECTANGLE(101,16, 109,30, 150,150,150)
  OLED.LINE(101,31, 109,31, 0,0,0)
  OLED.RECTANGLE(101,32, 109,74, 0,150,0)
  OLED.FONT_SIZE(1)
  OLED.UCHAR("O", 97,77, 0,0,0,1,1)
  OLED.FONT_SIZE(0)
  OLED.UCHAR("2", 105,80, 0,0,0,1,1)
   
  OLED.RECTANGLE( 138,20, 141,90, 0,0,0)
  OLED.LINE(136,25, 143,25, 0,0,0)
  OLED.LINE(136,30, 143,30, 0,0,0)
  OLED.LINE(136,35, 143,35, 0,0,0)
  OLED.LINE(136,40, 143,40, 0,0,0)
  OLED.LINE(136,45, 143,45, 0,0,0)
  OLED.LINE(136,50, 143,50, 0,0,0)
  OLED.LINE(136,55, 143,55, 0,0,0)
  OLED.LINE(136,60, 143,60, 0,0,0)
  OLED.LINE(136,65, 143,65, 0,0,0)
  OLED.LINE(136,70, 143,70, 0,0,0)
  OLED.LINE(136,75, 143,75, 0,0,0)
  OLED.LINE(136,80, 143,80, 0,0,0)
  OLED.LINE(136,85, 143,85, 0,0,0)
   
  OLED.LINE(135,52, 144,52, 220,220,220)
  OLED.LINE(134,53, 145,53, 100,100,100)
  OLED.LINE(134,54, 145,54, 0,0,0)
   
  OLED.CIRCLE(140,110,6, 200,0,0)
  OLED.CIRCLE(139,110,3, 255,100,100)
  OLED.PUT_PIXEL(138,110,250,250,250)
   
  DELAY.PauseSec(10)

  IF not SD_Demo
    SETUP

PUB MONITOR_2_uSD
  'Copy the previous screen, "MONITOR" to the uSD card at Sector 160 (80 Sectors)
  SAddr := 160
  OLED.SCREEN_2_uSD(0,0, 159,128, @SAddr)

  OLED.OPAQUE
  OLED.FTEXT(1,5, 2, 255,255,255, string("Screen Copied"),0)
  DELAY.PauseSec(3)
  SETUP
   
PUB DEVICEINFO
  'OLED.BACKGROUND(0,0,0)
  'DELAY.PauseSec(1)
      
  'OLED.DEVICE_INFO(1)
  'DELAY.PauseSec(4)
  'SETUP

PUB MONITOR_FROM_uSD
  'Displays the screen "MONITOR" that was copied to the uSD earlier
  OLED.OPAQUE 
  OLED.FTEXT(0,3, 2, 255,255,255, string("Display Copy of"),0)
  OLED.FTEXT(0,5, 2, 255,255,255, string("  'MONIROR'    "),0)
  OLED.FTEXT(0,7, 2, 255,255,255, string(" from uSD card "),0)
  DELAY.PauseSec(4)
  
  SAddr := 160
  OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)
  
  DELAY.PauseSec(3)
  SETUP

PUB STRIPCHART_FROM_uSD
  'Displays the screen "STRIPCHART" that was copied to the uSD earlier
  OLED.OPAQUE 
  OLED.FTEXT(0,3, 2, 255,255,255, string("Display Copy of"),0)
  OLED.FTEXT(0,5, 2, 255,255,255, string(" 'STRIPCHART'  "),0)
  OLED.FTEXT(0,7, 2, 255,255,255, string(" from uSD card "),0)
  DELAY.PauseSec(4)
   
  SAddr := 80
  OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)

  DELAY.PauseSec(3)
  SETUP

PUB WITCH_FROM_uSD
  'Displays the screen "WITCH" that was copied to the uSD earlier
  OLED.OPAQUE 
  OLED.FTEXT(0,3, 2, 255,255,255, string("Display Copy of"),0)
  OLED.FTEXT(0,5, 2, 255,255,255, string("    'WITCH'    "),0)
  OLED.FTEXT(0,7, 2, 255,255,255, string(" from uSD card "),0)
  DELAY.PauseSec(4)
   
  SAddr := 0
  OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)

  DELAY.PauseSec(3) 
  SETUP

PUB PART_SCREENS_FROM_uSD
  'Displays partial screens of the three "screen shots" saved to the uSD card
  OLED.OPAQUE 
  OLED.FTEXT(1,3, 2, 255,255,255, string("Display parts"),0)
  OLED.FTEXT(1,5, 2, 255,255,255, string("of all three "),0)
  OLED.FTEXT(1,7, 2, 255,255,255, string("saved screens"),0)
  DELAY.PauseSec(4)
  OLED.ERASE
  SAddr := 0
  OLED.DISPLAY_FROM_uSD(0,0, 159,40, 16, @SAddr)
  SAddr := 80
  OLED.DISPLAY_FROM_uSD(0,43, 159,40, 16, @SAddr)
  SAddr := 160
  OLED.DISPLAY_FROM_uSD(0,86, 159,40, 16, @SAddr)

  DELAY.PauseSec(4)
  SETUP

PUB FAST_IMAGES_FROM_uSD
  'Displays three images stored on the uSD at maximum speed
  OLED.OPAQUE
  OLED.FTEXT(1,3, 2, 255,255,255, string("'Flip' Images"),0)
  OLED.FTEXT(1,5, 2, 255,255,255, string("of all three "),0)
  OLED.FTEXT(1,7, 2, 255,255,255, string("saved screens"),0)
  OLED.FTEXT(1,7, 2, 255,255,255, string("at max speed "),0)
  DELAY.PauseSec(3)
  OLED.ERASE

  REPEAT 15
    SAddr := 0
    OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)     'WITCH
    OLED.ERASE
    SAddr := 80
    OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)     'STRIPCHART
    OLED.ERASE 
    SAddr := 160
    OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)     'MONITOR
    OLED.ERASE

  SAddr := 160
  OLED.DISPLAY_FROM_uSD(0,0, 159,128, 16, @SAddr)     'MONITOR 

  DELAY.PauseSec(2) 
  SETUP
  
PUB CONTRAST    
  OLED.ERASE
  OLED.BACKGROUND(00,00,00)
  DELAY.PauseMSec(500)
  OLED.FTEXT(2,2, 2, 255,255,255, string("Contrast Down"),0)
   
  OLED.FADE_OUT(300)
   
  DELAY.PauseSec(1)
  OLED.CONTRAST(15)
  SETUP
  DELAY.PauseSec(1)

PUB SHUTDOWN | Temp
  OLED.ERASE
  OLED.BACKGROUND(0,0,0)    
  OLED.OPAQUE
    
  OLED.FTEXT(2,2, 0, 255,255,255, string("Shutdown in:"),0)
  'OLED.FONT_SIZE(2)
  OLED.UCHAR("5", 90,8, 250,250,0, 2,2)
   
  OLED.FTEXT(3,8, 0, 250,250,0, string("Restart in 5 Sec"),0)
  DELAY.pauseSec(1)
  OLED.UCHAR("4", 90,8, 0,250,0, 2,2) 
  DELAY.pauseSec(1)
  OLED.UCHAR("3", 90,8, 250,250,0, 2,2) 
  DELAY.pauseSec(1)
  OLED.UCHAR("2", 90,8, 250,250,0, 2,2) 
  DELAY.pauseSec(1)
  OLED.UCHAR("1", 90,8, 250,0,0, 2,2) 
  DELAY.PauseSec(1)
  OLED.UCHAR("0", 90,8, 250,0,0, 2,2) 
  DELAY.PauseSec(1)
   
  OLED.ERASE
  DELAY.PauseMSec(20)    
      
  OLED.POWER(0)
  DELAY.PauseSec(4)
  OLED.POWER(1)
  DELAY.PauseMSec(500)
  'OLED.RESET
  OLED.AUTO_BAUD
  SETUP

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

  
   