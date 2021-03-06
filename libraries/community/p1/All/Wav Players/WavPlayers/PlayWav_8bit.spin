'  SPIN 8-bit WAV Player Ver. 1a  (Plays only mono 8-bit WAV at 8 or 16 ksps)
'  Copyright 2007 Raymond Allen  See end of file for terms of use. 
'  Settings for Demo Board Audio Output:  Right Pin# = 10, Left Pin# = 11   , VGA base=Pin16, TV base=Pin12


CON _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000       '80 MHz


PUB Main|n,i,j
  'Play a WAV File
  Player(@Wav,10,11)


PUB Player(pWav, PinR, PinL):bOK|n,i,nextCnt,rate,dcnt
  'Play the wav data using counter modules
  'although just mono, using both counters to play the same thing on both left and right pins

  'Set pins to output mode
  DIRA[PinR]~~                              'Set Right Pin to output
  DIRA[PinL]~~                              'Set Left Pin to output

  'Set up the counters
  CTRA:= %00110 << 26 + 0<<9 + PinR         'NCO/PWM Single-Ended APIN=Pin (BPIN=0 always 0)
  CTRB:= %00110 << 26 + 0<<9 + PinL         'NCO/PWM Single-Ended APIN=Pin (BPIN=0 always 0)   

  'get length
  n:=long[pWav+40]
  'get rate
  rate:=long[pWav+24]
  case rate
    8000:
      dcnt:=10000
    16000:
      dcnt:=5000
    other:
      return false
  'jump over header    
  pWav+=44   'ignore rest of header (so you better have the right file format!)


  'Get ready for fast loop  
  n--
  i:=0
  NextCnt:=cnt+15000

  'Play loop
  repeat i from 0 to n
    NextCnt+=dcnt   ' need this to be 5000 for 16KSPS   @ 80 MHz
    waitcnt(NextCnt)
    FRQA:=(byte[pWav+i])<<24
    FRQB:=FRQA

       
      'Easy high-impedance output (e.g., to "line in" input of computer or sound system)
      '
      '              R=100
      ' Prop Pin ────┳──────── Audio Out
       '               C=0.1uF
       '                
       '               Vss
  return true

  
DAT

WAV byte
'File "test8a.wav"           '   <---  put your 8-bit PCM mono 16000 or 8000 sample/second WAV filename here
'File "test8b.wav"           '   <---  put your 8-bit PCM mono 16000 or 8000 sample/second WAV filename here
File "test8c.wav"           '   <---  put your 8-bit PCM mono 16000 or 8000 sample/second WAV filename here

{{
                            TERMS OF USE: MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}
       