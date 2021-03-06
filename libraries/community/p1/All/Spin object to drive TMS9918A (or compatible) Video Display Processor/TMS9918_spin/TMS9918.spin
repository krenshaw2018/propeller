{{
-----------------------------------------------------------------------------------------------
Object to interface with TMS9918/19/28/29 Video Display Processor (or F18A FPGA implementation)
-----------------------------------------------------------------------------------------------
Author: zpekic@hotmail.com (use freely, but give credit, that's what it boils down to)
-----------------------------------------------------------------------------------------------
This object was developed based on following documentation:
https://github.com/cbmeeks/TMS9918
http://codehackcreate.com/archives/30
-----------------------------------------------------------------------------------------------
It has been tested on F18A, but not real TMS99x8/9 family. In order to work on retro-hardware,
modifications may be needed, most notably delays in the read/update/write cycle (consuming the
line scan interrupt to make the changes only during scan times outside of visible area. F18A
has much higher memory bandwith and no such limitations.
----------------------------------------------------------------------------------------------
Version         Date            Notes
----------------------------------------------------------------------------------------------
0.91            2017-07-04      Added basic sprite support, and flags to turn on/off interrupt
                                wait and console logging. GRAPHICS2 mode still blows up... :-(
0.90            2017-06-03      Basic text and graphics primities, no sprites. GRAPHICS2 mode
                                still has a bug that is causing random scrambling of the display
                                after some number of drawing operations are executed      
----------------------------------------------------------------------------------------------
See demo video here: https://youtu.be/FW8V7gS8_GI
----------------------------------------------------------------------------------------------
}}

CON
        _clkmode = xtal1 + pll16x  'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

CON
  STACK_LEN = 64
  
CON
'Signal     Propeller pin   VDP pin ( == F18A pins)
nRESET =    12'             34 == pull low for reset
MODE =      11'             13 == memory/register mode
nCSW =      10'             14 == write to register or VDP memory
nCSR =      9'      '       15 == read from register or VDP memory                       
nINT =      8'              16 == input always, activated after each scan line if enabled
CD0 =       7'              24 == MSB (to keep with "reverse" TMS99XX family documentation)           
CD1 =       6'              23
CD2 =       5'              22
CD3 =       4'              21
CD4 =       3'              20
CD5 =       2'              19
CD6 =       1'              18
CD7 =       0'              17 == LSB
'VSS                        12 == GND
'VCC                        33 == +5V
'
' Colors
TRANSPARENT     = 0
BLACK           = 1
MEDIUMGREEN     = 2
LIGHTGREEN      = 3
DARKBLUE        = 4
LIGHTBLUE       = 5
DARKRED         = 6
CYAN            = 7
MEDIUMRED       = 8
LIGHTRED        = 9
DARKYELLOW      = $A
LIGHTYELLOW     = $B
DARKGREEN       = $C
MAGENTA         = $D
GRAY            = $E
WHITE           = $F

' Video modes
GRAPHICS1       = $0
GRAPHICS2       = $1
MULTICOLOR      = $2
TEXT            = $3

' Sprite modes
SPRITESIZE_8X8                  = %0000_0000
SPRITESIZE_16X16                = %0000_0010
SPRITEMAGNIFICATION_NONE        = %0000_0000
SPRITEMAGNIFICATION_2X          = %0000_0001
' SetSprite() masks allow fine-grained updates
SPRITEMASK_SETPATTERN           = $01
SPRITEMASK_SETCOLOR             = $02
SPRITEMASK_SETX                 = $04 'will override SPRITEMASK_DX
SPRITEMASK_SETY                 = $08 'will override SPRITEMASK_DY
SPRITEMASK_DX                   = $10
SPRITEMASK_DY                   = $20
SPRITEMASK_VX                   = $40
SPRITEMASK_VY                   = $80

' Commands, 0 params
CMD_NOOP        = $00
CMD_BLANK       = $01
CMD_DISPLAY     = $02
CMD_RESET       = $03
CMD_HOME        = $04
CMD_CLS         = $05
' Commands, 1 param
CMD_SETMODE       = $10
CMD_WRITETEXT     = $11
CMD_SETSPRITEMODE = $12
' Commands, 2 param
CMD_SETCOLORS   = $20
' Commands, 3 param
CMD_DRAWPIXEL   = $30
CMD_READMEM     = $31
CMD_WRITEMEM    = $32
CMD_SETSPRITEPATTERN = $34
' Commands, 4 param
CMD_FILLMEM     = $40
CMD_DRAWCIRCLE  = $41
' Commands, 5 param
CMD_DRAWTEXT    = $50
CMD_DRAWLINE    = $51
' Commands, 6 param
CMD_SETSPRITE   = $60

'Some ASCII codes with special handling during WriteText
CS = 16  ''CS: Clear Screen      
HM =  1  ''HM: HoMe cursor       
NL = 13  ''NL: New Line
CR = 13  ''CR: Carriage return == NL       
LF = 10  ''LF: Line Feed       
ML =  3  ''ML: Move cursor Left          
MR =  4  ''MR: Move cursor Right         
MU =  5  ''MU: Move cursor Up          
MD =  6  ''MD: Move cursor Down
TB =  9  ''TB: TaB          
BS =  8  ''BS: BackSpace     


VAR
  long  stack[STACK_LEN]
  byte  lockCommandBuffer
  byte  cogCurrent
  byte  reg[8] '"shadow" registers for read access convenience, as the VDP only allows writing to them
  long  plCommand
  long  lastScanCnt
  byte  lastStatus
  long  vdpAccessWindow
  long  skipTrace

  LONG displayMode
  LONG nextCharRow, nextCharCol
  LONG lastCharRow, lastCharCol
  LONG lastPixY, lastPixX
  LONG lastSpriteY, lastSpriteX
  BYTE colorGraphicsForeAndBack
  
  WORD spriteSpeed[32]
  LONG lastSpritePositionUpdateCnt[32]

OBJ
  pst      : "Parallax Serial Terminal"

PUB Start(plCommandBuffer, initialMode, useInterrupt, enableTracing) : success

  longfill(@stack, 0, STACK_LEN)
  skipTrace := true
  if (enableTracing)
    pst.Start(115_200)
    pst.Clear
    skipTrace := false

  Stop

  plCommand := plCommandBuffer
  longfill(@spriteSpeed, 0, 32)
  colorGraphicsForeAndBack := byte[@GoodContrastColorsTable]  
  
  _prompt(String("Press any key to continue with TMS9918 object start using command buffer at "), plCommand)

  lockCommandBuffer := locknew
  if (lockCommandBuffer == -1)
    _logError(String("No locks available to start object!"))
    return false
  else
    cogCurrent := cognew(_vdpProcess(initialMode, useInterrupt), @stack)
    if (cogCurrent == -1)
      _logError(String("No cogs available to start object!"))
      lockret(lockCommandBuffer~)
      return false
  waitcnt((clkfreq * 1) + cnt)
  _logTrace(String("TMS9918 object launched into cog "), cogCurrent, String(" using lock "), lockCommandBuffer, String(" at clkfreq "), clkfreq, 0)
  return true

PUB Stop
  if lockCommandBuffer <> -1
    _logTrace(String("Returning TMS9918 object lock "), lockCommandBuffer, 0, 0, 0, 0, 0)
    lockret(lockCommandBuffer~)    
  if cogCurrent > 0
    _logTrace(String("Stopping TMS9918 object cog "), cogCurrent, 0, 0, 0, 0, 0)
    cogstop(cogCurrent~)

PRI _vdpProcess(initialMode, useInterrupt) |i, y, timer
  _logTrace(String("TMS9918 object starting in cog "), cogId, String(" using lock "), lockCommandBuffer, String(" at clkfreq "), clkfreq, 0) 

  nextCharRow := 0
  nextCharCol := 0
  if (useInterrupt)
    vdpAccessWindow := ((((clkfreq / 60) * (262 - 192)) / 262) * 95) / 100 'see table 3.3 in TMS9918 documentation (we have 70 scan lines every 1/60s)
  else
    vdpAccessWindow := clkfreq / 60
  _logTrace(String("Initial mode is "), initialMode, String(" use interrupt is "), useInterrupt, String(" vdp access clock cycles is "), vdpAccessWindow, 0)

  outa[nReset .. CD7]~~         'set all to 1 (inactive)
  dira[nReset .. CD7]~          'set all to input first
  dira[nReset .. nCSR]~~        'these are always outputs
  _vdpReset
  _setReg(1, reg[1] & %1011_1111) 'blank screen
  lastStatus := _readStatus
  _fillVdpMem(0, 16 * 1024, 0, 0)
  'this is the first command that will be executed
  long[plCommand][0] := CMD_SETMODE
  long[plCommand][1] := initialMode
  displayMode := initialMode
  longfill(@lastSpritePositionUpdateCnt, cnt, 32)
  repeat  'keep executing commands until cog is stopped
    repeat until not lockset(lockCommandBuffer) 'wait for the free lock (don't execute while command buffer is updated)

    'update position of even numbered sprites according to their speed, if set
    _updateSpritePositions(0)

    timer := cnt
    case LONG[plCommand]
      CMD_SETSPRITEMODE:
        _setSpriteMode(long[plCommand][1] & %0000_0011)
        _logCommand(String("CMD_SETSPRITEMODE in mode "), _interval(cnt, timer))

      CMD_SETSPRITEPATTERN:
        _copyToVdpMem(SpritePatternTable + (long[plCommand][1] << 3), long[plCommand][2], long[plCommand][3])
        _logCommand(String("CMD_SETSPRITE in mode "), _interval(cnt, timer))

      CMD_SETSPRITE:
        _setSprite(long[plCommand][1], long[plCommand][2], long[plCommand][3], long[plCommand][4], long[plCommand][5], long[plCommand][6])
        _logCommand(String("CMD_SETSPRITE in mode "), _interval(cnt, timer))
        
      CMD_HOME:
        _homeTextScreen
        _logCommand(String("CMD_HOME in mode "), _interval(cnt, timer))

      CMD_CLS:
        case displayMode
          GRAPHICS1, TEXT:
            _homeTextScreen
            _clearTextScreen
          GRAPHICS2:
            _fillVdpMem(PatternTable, (256 * 192) / 8, 0, 0)
          MULTICOLOR:
            _fillVdpMem(PatternTable, (64 * 48) / 2, (colorGraphicsForeAndBack << 4) | (colorGraphicsForeAndBack & $F), 0)
        _logCommand(String("CMD_CLS in mode "), _interval(cnt, timer))

      CMD_FILLMEM:
        _fillVdpMem(long[plCommand][1], long[plCommand][2], long[plCommand][3], long[plCommand][4])
        _logCommand(String("CMD_FILLMEM in mode "), _interval(cnt, timer))

      CMD_READMEM:
        _copyFromVdpMem(long[plCommand][1], long[plCommand][2], long[plCommand][3])
        _logCommand(String("CMD_READMEM in mode "), _interval(cnt, timer))

      CMD_WRITEMEM:
        _copyToVdpMem(long[plCommand][1], long[plCommand][2], long[plCommand][3])
        _logCommand(String("CMD_WRITEMEM in mode "), _interval(cnt, timer))

      CMD_DRAWPIXEL:
        _drawPixel(long[plCommand][1], long[plCommand][2], long[plCommand][3])
        _logCommand(String("CMD_DRAWPIXEL in mode "), _interval(cnt, timer))

      CMD_DRAWLINE:
        _drawLine(long[plCommand][1], long[plCommand][2], long[plCommand][3], long[plCommand][4], long[plCommand][5])
        _logCommand(String("CMD_DRAWLINE in mode "), _interval(cnt, timer))

      CMD_DRAWCIRCLE:
        _drawCircle(long[plCommand][1], long[plCommand][2], long[plCommand][3], long[plCommand][4])
        _logCommand(String("CMD_DRAWCIRCLE in mode "), _interval(cnt, timer))

      CMD_DRAWTEXT:
        _drawText(long[plCommand][1], long[plCommand][2], long[plCommand][3], long[plCommand][4], long[plCommand][5])
        _logCommand(String("CMD_DRAWTEXT in mode "), cnt - timer)

      CMD_WRITETEXT:
        _writeText(long[plCommand][1])
        _logCommand(String("CMD_WRITETEXT in mode "), _interval(cnt, timer))

      CMD_SETCOLORS:
        _setReg(7, long[plCommand][2])
        'in case this is called before SET_MODE, overwrite default reg7 for all modes
        byte[@Mode_Graphics1][7] := reg[7]
        byte[@Mode_Graphics2][7] := reg[7]
        byte[@Mode_Multicolor][7] := reg[7]
        byte[@Mode_Text][7] :=  reg[7]
        colorGraphicsForeAndBack := long[plCommand][1]
        case displayMode
          GRAPHICS1:
            _fillVdpMem(ColorTable, 32, colorGraphicsForeAndBack, 0)
          GRAPHICS2:
            _fillVdpMem(ColorTable, (256 * 192) / 8, colorGraphicsForeAndBack, 0)
        _logCommand(String("CMD_SETCOLORS in mode "), _interval(cnt, timer))

      CMD_SETMODE:
        displayMode := long[plCommand][1]
        case displayMode
          GRAPHICS1:
            _initialize(32, 24, 0, 0, 256, 192, @Mode_Graphics1, useInterrupt)
            _initCharTable(PatternTable, false)
            _fillVdpMem(ColorTable, 32, colorGraphicsForeAndBack, 0)
            _homeTextScreen
            _clearTextScreen
            _setReg(1, reg[1] | %0100_0000) 'show screen
            '_logTrace2(String("Name table: "), NameTable, String(" Pattern table: "), PatternTable, String(" Color table: "), ColorTable, 8)
            _logCommand(String("CMD_SETMODE to mode "), _interval(cnt, timer))
          GRAPHICS2:
            _initialize(0, 0, 256, 192, 256, 192, @Mode_Graphics2, useInterrupt)
            _fillVdpMem(PatternTable, (256 * 192) / 8, 0, 0)
            _fillVdpMem(ColorTable, (256 * 192) / 8, colorGraphicsForeAndBack, 0)
            _fillVdpMem(NameTable + 000, 256, 0, 1)
            _fillVdpMem(NameTable + 256, 256, 0, 1)
            _fillVdpMem(NameTable + 512, 256, 0, 1)
            _setReg(1, reg[1] | %0100_0000) 'show screen
            '_logTrace2(String("Name table: "), NameTable, String(" Pattern table: "), PatternTable, String(" Color table: "), ColorTable, 8)
            _logCommand(String("CMD_SETMODE to mode "), _interval(cnt, timer))
          MULTICOLOR:
            _initialize(0, 0, 64, 48, 256, 192, @Mode_Multicolor, useInterrupt)
            _fillVdpMem(PatternTable, (64 * 48) / 2, (colorGraphicsForeAndBack << 4) | (colorGraphicsForeAndBack & $0F), 0)
            repeat y from 0 to 23
              _fillVdpMem(NameTable + (y << 5), 32, 32 * (y >> 2), 1)
            _setReg(1, reg[1] | %0100_0000) 'show screen
            '_logTrace2(String("Name table: "), NameTable, String(" Pattern table: "), PatternTable, String(" Color table: "), ColorTable, 8)
            _logCommand(String("CMD_SETMODE to mode "), _interval(cnt, timer))
          TEXT:
            _initialize(40, 24, 0, 0, 0, 0, @Mode_Text, useInterrupt)
            _initCharTable(PatternTable, true)
            _homeTextScreen
            _clearTextScreen
            _setReg(1, reg[1] | %0100_0000) 'show screen
            '_logTrace2(String("Name table: "), NameTable, String(" Pattern table: "), PatternTable, String(" Color table: "), ColorTable, 8)
            _logCommand(String("CMD_SETMODE to mode "), _interval(cnt, timer))
          other:
            _logError(String("Not a valid video mode."))

      CMD_BLANK:
        _setReg(1, reg[1] & %1011_1111)
        _logCommand(String("CMD_BLANK in mode "), _interval(cnt, timer))

      CMD_DISPLAY:
        _setReg(1, reg[1] | %0100_0000)
        _logCommand(String("CMD_DISPLAY in mode "), _interval(cnt, timer))

      CMD_RESET: 'Definitely call SetMode() after this command!
        _vdpReset
        _logCommand(String("CMD_RESET in mode "), _interval(cnt, timer))

      CMD_NOOP:

    long[plCommand] := CMD_NOOP

    'update position of odd numbered sprites according to their speed, if set
    _updateSpritePositions(1)

    lockclr(lockCommandBuffer)

{{
Commands to be executed by VDP. Note that these execute in the calling cog, and the parameters are copied over to a common
main memory buffer to be picked up by the cog driving the VDP. A single lock (mutex) is used to avoid the VDP cog to start
consuming half-copied command buffer. This could be expanded into a deeper FIFO to further parallelize visual command exe-
cution (right now caller cog will wait for VDP cog before executing next command but otherwise it will proceed with other
work).
}}

PUB Reset
  _setCommand(CMD_RESET, 0, 0, 0, 0, 0, 0, 0)

PUB Display
  _setCommand(CMD_DISPLAY, 0, 0, 0, 0, 0, 0, 0)

PUB Blank
  _setCommand(CMD_BLANK, 0, 0, 0, 0, 0, 0, 0)

PUB Cls
  _setCommand(CMD_CLS, 0, 0, 0, 0, 0, 0, 0)

PUB Home
  _setCommand(CMD_HOME, 0, 0, 0, 0, 0, 0, 0)

PUB DrawText(pbText, columnLeft, rowTop, columnRight, rowBottom)
  _setCommand(CMD_DRAWTEXT, pbText, columnLeft, rowTop, columnRight, rowBottom, 0, 0)

PUB WriteText(pbText)
  _setCommand(CMD_WRITETEXT, pbText, 0, 0, 0, 0, 0, 0)

PUB SetColors(colorsGraphics, colorsText)
  _setCommand(CMD_SETCOLORS, colorsGraphics, colorsText, 0, 0, 0, 0, 0)

PUB SetMode(vdpMode)
  _setCommand(CMD_SETMODE, vdpMode, 0, 0, 0, 0, 0, 0)

PUB DrawPixel(x, y, color)
  _setCommand(CMD_DRAWPIXEL, x, y, color, 0, 0, 0, 0)

PUB DrawLine(xs, ys, xe, ye, color)
  _setCommand(CMD_DRAWLINE, xs, ys, xe, ye, color, 0, 0)

PUB DrawCircle(xc, yc, radius, color)
  _setCommand(CMD_DRAWCIRCLE, xc, yc, radius, color, 0, 0, 0)

PUB FillMem(pbVdp, count, value, increment)
  _setCommand(CMD_FILLMEM, pbVdp, count, value, increment, 0, 0, 0)

PUB ReadMem(pbVdp, pbMain, count)
  _setCommand(CMD_READMEM, pbVdp, pbMain, count, 0, 0, 0, 0)

PUB WriteMem(pbVdp, pbMain, count)
  _setCommand(CMD_WRITEMEM, pbVdp, pbMain, count, 0, 0, 0, 0)

PUB SetSpriteMode(spriteMode)
  _setCommand(CMD_SETSPRITEMODE, spriteMode, 0, 0, 0, 0, 0, 0)

PUB SetSpritePattern(patternId, patternAddr, patternLen)
  if (patternId > 255)
    _logError(String("Invalid patternId in SetSpritePattern()."))
  else
    if (patternLen == 8)
      _setCommand(CMD_SETSPRITEPATTERN, patternId, patternAddr, patternLen, 0, 0, 0, 0)
      return
    if (patternLen == 32)
      if (patternId & $3)
        _logError(String("Invalid patternId in SetSpritePattern(). For 32 byte sprites, must be divisible by 4."))
      else
        _setCommand(CMD_SETSPRITEPATTERN, patternId, patternAddr, patternLen, 0, 0, 0, 0)
      return
  _logError(String("Invalid patternLen in SetSpritePattern()."))
    
PUB SetSprite(spriteId, mask, patternId, xpos, ypos, color)
  if ((spriteId > 31) or (mask == 0))
    _logError(String("Invalid SetSprite() params."))
  else 
    _setCommand(CMD_SETSPRITE, spriteId, mask, patternId, xpos, ypos, color, 0)

PUB GenerateSpritePatternFromChar(pDest, char, size) |offset, mask, i
  if (char > 127)
    offset := (char - 128) << 3
    mask := $00
  else
    offset := char << 3
    mask := $FF
  if (size == 8)
    repeat i from 0 to 7
      byte[pDest][i] := mask
      byte[pDest][i] ^= byte[@CharGen8X8 + offset][i]
    return
  if (size == 32)
    repeat i from 0 to 31
      byte[pDest][i] := mask
      case i
        4..11:
          byte[pDest][i] ^= ((byte[@CharGen8X8 + offset][i - 4] >> 4) & $0F)
        20..27:
          byte[pDest][i] ^= ((byte[@CharGen8X8 + offset][i - 20] << 4) & $F0)
    return
  _logError(String("Invalid params in GenerateSpritePatternFromChar()"))
  
{{ Read - only properties}}
PUB NameTable
  return (reg[2] & $0F) * $400

PUB ColorTable
  if (displayMode == GRAPHICS2)
    if (reg[3] & %1000_0000) 'This is simplification as real TMS9918 only recognizes $FF and $7F
      return $2000
    else
      return $0000
  else
    return reg[3] * $40
  
PUB PatternTable
  if (displayMode == GRAPHICS2)
    if (reg[4] & %0000_1000) 'This is a simplification as real TMS9918 only recognizes $07 and $03
      return $2000
    else
      return $0000
  return (reg[4] & $07) * $800
   
PUB SpriteAttributeTable
  '_logTrace(String("reg[5]= "), reg[5], String(" SpriteAttributeTable= "), (reg[5] & $7F) * $80, 0, 0, 0)
  return (reg[5] & $7F) * $80

PUB SpritePatternTable
  '_logTrace(String("reg[6]= "), reg[6], String(" SpritePatternTable= "), (reg[6] & $07) * $800, 0, 0, 0)
  return (reg[6] & $07) * $800

PUB TextRowCount
  return lastCharRow + 1

PUB TextColumnCount
  return lastCharCol + 1

PUB GraphicsVPixelCount
  _logTrace(String("Mode is "), displayMode, String(" GraphicHPixelCount is "), lastPixX + 1 , String(" *GraphicsVPixelCount is "), lastPixY + 1, 8)
  return lastPixY + 1

PUB GraphicsHPixelCount
  _logTrace(String("Mode is "), displayMode, String(" *GraphicHPixelCount is "), lastPixX + 1 , String(" GraphicsVPixelCount is "), lastPixY + 1, 8)
  return lastPixX + 1

PUB SpriteVPixelCount
  return lastSpriteY + 1

PUB SpriteHPixelCount
  return lastSpriteX + 1
  
PUB GoodContrastColors(index)
  return byte[@GoodContrastColorsTable][index & $F]

PUB CurrentDisplayMode
  return displayMode

{{ Push parameters to memory shared by cogs }}
PRI _setCommand(cmd, param1, param2, param3, param4, param5, param6, param7)
  repeat until not lockset(lockCommandBuffer) 'this will block until VDP cog is done executing previous command
  LONG[plCommand][0] := cmd
  LONG[plCommand][1] := param1
  LONG[plCommand][2] := param2
  LONG[plCommand][3] := param3
  LONG[plCommand][4] := param4
  LONG[plCommand][5] := param5
  LONG[plCommand][6] := param6
  LONG[plCommand][7] := param7
  lockclr(lockCommandBuffer)

{{
Private sprite methods
}}
PRI _updateSpritePositions(startId) |i
  repeat i from startId to 31 step 2
    if (spriteSpeed[i] and ((cnt - lastSpritePositionUpdateCnt[i]) > (clkfreq / 10)))
      lastSpritePositionUpdateCnt[i] := cnt
      _setSprite(i, SPRITEMASK_DX | SPRITEMASK_DY, 0, byte[@spriteSpeed + (i << 1)][1],  byte[@spriteSpeed + (i << 1)][0], 0)

PRI _setSpriteMode(spriteMode)
  _setReg(1, reg[1] & %1111_1100 | spriteMode)

PRI _setSprite(spriteId, mask, patternId, x, y, color) |spriteAttributeAddress
  spriteAttributeAddress := SpriteAttributeTable + (spriteId << 2)
  _copyFromVdpMem(spriteAttributeAddress, @SpriteBuff, 4)
  '_logSprite(String("Sprite before "), spriteAttributeAddress, @SpriteBuff)
  if (mask & SPRITEMASK_SETY)
    byte[@SpriteBuff][0] := y
  else
    if (mask & SPRITEMASK_DY)
      byte[@SpriteBuff][0] += y
    else
      if (mask & SPRITEMASK_VY)
        byte[@spriteSpeed + (spriteId << 1)][1] := y
  if (mask & SPRITEMASK_SETX)
    byte[@SpriteBuff][1] := x
  else  
    if (mask & SPRITEMASK_DX)
      byte[@SpriteBuff][1] += x
    else
      if (mask & SPRITEMASK_VX)
        byte[@spriteSpeed + (spriteId << 1)][0] := x
  if (mask & SPRITEMASK_SETPATTERN)
    byte[@SpriteBuff][2] := patternId
  if (mask & SPRITEMASK_SETCOLOR)
    byte[@SpriteBuff][3] := (byte[@SpriteBuff][3] & $F0) | (color & $0F)
  '_logSprite(String("Sprite after  "), spriteAttributeAddress, @SpriteBuff)
  _copyToVdpMem(spriteAttributeAddress, @SpriteBuff, 4)
  
{{
Private drawing methods
}}
PRI _drawLine(xs, ys, xe, ye, color) |x, y, dx, dy, stepx, stepy, pixCount
  '_logTrace(String("Drawing line in color "), color, String(" from "), xs << 16 | ys , String(" to "), xe << 16 | ye, 8)
  pixCount := 0
  dx := xe - xs
  dy := ye - ys
  if (dx)
    if (dx < 0)
      stepx := -1
    else
      stepx := 1
    if (dy) 'dx != 0
      if (dy < 0)
        stepy := -1
      else
        stepy := 1
      x := xs
      y := ys
      if (||dy > ||dx)
        repeat while (y - ye)
          pixCount += _drawPixel(x, y, color)
          y := y + stepx
          if (_lineError(x + stepx, xs, y, ys, dx, dy) < _lineError(x, xs, y, ys, dx, dy))
            x := x + stepx
      else
        repeat while (x - xe)
          pixCount += _drawPixel(x, y, color)
          x := x + stepx
          if (_lineError(x, xs, y + stepy, ys, dx, dy) < _lineError(x, xs, y, ys, dx, dy))
            y := y + stepy
      pixCount += _drawPixel(xe, ye, color) 'because repeats above will bail before reaching last pixel
    else
      '_logTrace(String("Horizontal line in color "), color, String(" from "), xs << 16 | ys , String(" to "), xe << 16 | ye, 8)
      repeat x from xs to xe 'dy == 0, horizontal line
        pixCount += _drawPixel(x, ys, color)
  else
    if (dy) 'dx == 0
      '_logTrace(String("Vertical line in color "), color, String(" from "), xs << 16 | ys , String(" to "), xe << 16 | ye, 8)
      repeat y from ys to ye 'dy != 0, vertical line
        pixCount += _drawPixel(xs, y, color)
    else
      pixCount += _drawPixel(xs, ys, color) 'dy == 0, single dot
  return pixCount

PRI _lineError(x, x0, y, y0, dx, dy)
  return ||((y - y0) * dx - (x - x0) * dy) 

PRI _drawCircle(xc, yc, radius, color) |x, y, x2, y2, r2, x2m, pixCount
  '_logTrace(String("Drawing circle in color "), color, String(" at "), xc << 16 | yc , String(" with radius "), radius, 8)
  if (radius < 1)
    return 0
  pixCount := 0
  x := radius
  y := 0
  r2 := radius * radius
  x2 := r2
  y2 := 0
  repeat while (y =< x)
    pixCount += _drawPixel(xc + x, yc + y, color)
    pixCount += _drawPixel(xc + x, yc - y, color)
    pixCount += _drawPixel(xc - x, yc + y, color)
    pixCount += _drawPixel(xc - x, yc - y, color)
    pixCount += _drawPixel(xc + y, yc + x, color)
    pixCount += _drawPixel(xc + y, yc - x, color)
    pixCount += _drawPixel(xc - y, yc + x, color)
    pixCount += _drawPixel(xc - y, yc - x, color)
    y2 := y2 + y + y + 1
    y++
    x2m := x2 - x - x + 1
    if (_circleError(x2m, y2, r2) < _circleError(x2, y2, r2))
      x--
      x2 := x2m

PRI _circleError(x2, y2, r2)
  return ||(r2 - x2 - y2)     

PRI _drawPixel(x, y, color) |pVdp, pixByte, mask, name, pixWord
  if ((x < 0) or (x > lastPixX))
    return 0
  if ((y < 0) or (y > lastPixY))
    return 0
  case displayMode
    GRAPHICS2:
      pVdp := PatternTable + ((x >> 3) + (y >> 3) << 5) << 3 + (y & $7)
      if (pVdp & $FFFF_C000)
        _prompt(String("pVdp="), pVdp)

      'Get a byte from video memory at the right pixel address
      _vdpWrite(pVdp.byte[0], 1) 
      _vdpWrite(%0000_0000 | pVdp.byte[1], 1) 
      pixByte := _vdpRead(0)
      'Write back to same place with single bit set or reset
      '_logTrace(String("Drawing pixel in color "), color, String(" at "), x << 16 | y , String(" in memory location "), pVdp, 8)
      _vdpWrite(pVdp.byte[0], 1) 
      _vdpWrite(%0100_0000 | pVdp.byte[1], 1)
      _vdpWrite(lookupz(color & $01 : pixByte & byte[@AndMask + (x & 7)], pixByte | byte[@OrMask + (x & 7)]), 0) 
      'if (color & $01)
      '  _vdpWrite(pixByte | byte[@OrMask + (x & 7)] , 0)
      'else
      '  _vdpWrite(pixByte & byte[@AndMask + (x & 7)], 0)
      return 1 'return of 1 means visible pixel was changed, and 0 not changed
    MULTICOLOR:
      pVdp := PatternTable + ((x >> 1) + (y >> 3) << 5) << 3 + (y & $7)
      if (pVdp & $FFFF_C000)
        _prompt(String("pVdp="), pVdp)

      'Get a byte from video memory at the right pixel address
      _vdpWrite(pVdp.byte[0], 1) 
      _vdpWrite(%0000_0000 | pVdp.byte[1], 1) 
      pixByte := _vdpRead(0)
      'Write back to same place with upper or lower nibble set to color
      '_logTrace(String("Drawing pixel in color "), color, String(" at "), x << 16 | y , String(" in memory location "), pVdp, 8)
      _vdpWrite(pVdp.byte[0], 1) 
      _vdpWrite(%0100_0000 | pVdp.byte[1], 1)
      _vdpWrite(lookupz(x & $1 : (color << 4) | (pixByte & $0F), (color & $0F) | (pixByte & $F0)), 0)
      'if (x & $01)
      '  _vdpWrite((color & $0F) | (pixByte & $F0), 0)
      'else
      '  _vdpWrite((color << 4) | (pixByte & $0F), 0)
      return 1 
    other:
      return 0
       
PRI _drawText(pbText, columnLeft, rowTop, columnRight, rowBottom)|row, column, char
  '_logTrace(pbText, displayMode, String(" from "), columnLeft << 16 | rowTop , String(" to "), columnRight << 16 | rowBottom, 8)
  repeat row from rowTop to rowBottom
    repeat column from columnLeft to columnRight
      char := byte[pbText++]
      if (char)
        if ((row => 0) and (row =< lastCharRow) and (column => 0) and (column =< lastCharCol))
          _writeCharAt(char, row, column)
      else
        return
  
PRI _writeText(pbText)  |char, colOffset
  repeat
    char := byte[pbText++]
    case char
      0: return 'end of string
      CS: 'clear screen
        _clearTextScreen
      HM: 'home cursor
        _homeTextScreen
      LF: 'Line feed, just move one line down, which may cause scrolling
        _moveCursorDown
        'nextCharCol := 0 'uncommment if you want LF to act as CR+LF
      NL: 'Carriage return, move to first left position in this line
        nextCharCol := 0
        '_moveCursorDown 'uncomment if you want CR to act as CR+LF
      ML: 'move cursor left
        _moveCursorLeft
      MR: 'move cursor right
        _moveCursorRight
      MU: 'move cursor up
        nextCharRow--
        if (nextCharRow < 0)
          nextCharRow := 0
          _scrollDown
      MD:
        _moveCursorDown
      TB: 'tab (1 tab is 8 chars, so we have 4 or 5 tabs per line)
        colOffset := nextCharCol & $7
        if (colOffset)
          repeat (8 - colOffset)
            _moveCursorRight
      BS: 'backspace (== move towards left and clear the position)
        _moveCursorLeft
        _writeCharAt(" ", nextCharRow, nextCharCol)
      other:
        _writeCharAt(char, nextCharRow, nextCharCol)
        _moveCursorRight

PRI _moveCursorUp
  nextCharRow--
  if (nextCharRow < 0)
    nextCharRow := 0
    _scrollDown

PRI _moveCursorDown
  nextCharRow++
  if (nextCharRow > lastCharRow)
    nextCharRow := lastCharRow
    _scrollUp                   

PRI _moveCursorLeft
  nextCharCol--
  if (nextCharCol < 0)
    nextCharCol := lastCharCol
    _moveCursorUp
             
PRI _moveCursorRight        
  nextCharCol++
  if (nextCharCol > lastCharCol)
    nextCharCol := 0
    _moveCursorDown

PRI _writeCharAt(char, row, col) |pVdp
  pVdp := NameTable + row * (lastCharCol + 1) + col
  _vdpWrite(pVdp.byte[0], 1) 
  _vdpWrite(%0100_0000 | pVdp.byte[1], 1)
  _vdpWrite(char, 0) 
      
PRI _homeTextScreen
  nextCharRow := 0
  nextCharCol := 0

PRI _clearTextScreen
  _fillVdpMem(NameTable, (lastCharRow + 1) * (lastCharCol + 1), " ", 0)

PRI _scrollUp |row, colCount
  colCount := lastCharCol + 1
  repeat row from 1 to lastCharRow
    _copyFromVdpMem(NameTable + colCount * row, @RowBuff, colCount)
    _copyToVdpMem(NameTable + colCount * (row - 1), @RowBuff, colCount)
  _fillVdpMem(NameTable + colCount * lastCharRow, colCount, " ", 0) 'fill last row with spaces

PRI _scrollDown|row, colCount
  colCount := lastCharCol + 1
  repeat row from lastCharRow - 1 to 0
    _copyFromVdpMem(NameTable + colCount * row, @RowBuff, colCount)
    _copyToVdpMem(NameTable + colCount * (row + 1), @RowBuff, colCount)
  _fillVdpMem(NameTable, colCount, " ", 0) 'fill first row with spaces

{{
Other private methods
}}
PRI _initialize(charWidth, charHeight, pixelWidth, pixelHeight, spriteWidth, spriteHeight, pRegs, enableInterrupt) |index
  wordfill(@spriteSpeed, 0, 32)
  lastCharCol := charWidth - 1
  lastCharRow := charHeight - 1
  lastPixX := pixelWidth - 1
  lastPixY := pixelHeight - 1
  lastSpriteX := spriteWidth - 1 
  lastSpriteY := spriteHeight - 1
  repeat index from 0 to 7
    if (index == 1)
      _setReg(index, byte[pRegs][index] & %1011_1111) 'force screen turn off
    else
      _setReg(index, byte[pRegs][index])
  if (enableInterrupt)
    _setReg(1, reg[1] | %0010_0000) 'enable interrupt
    
PRI _initCharTable(pVdpDest, use5x7)| invert, pattern, pMemSrc, mask, i
  _vdpWrite(pVdpDest.byte[0], 1) 
  _vdpWrite(%0100_0000 | pVdpDest.byte[1], 1) 
  repeat invert from 0 to 1 'non-reverse and reverse
    if (use5x7)
      pMemSrc := @CharGen5x7
      repeat 128
        repeat i from 7 to 0 'flip rows from chargen (5 bytes) and fill 3 with 0
          if (i > 2)
            byte[RowBuff][i] := byte[pMemSrc++]
          else
            byte[RowBuff][i] := 0
        mask := %1000_0000
        repeat 8 'rotate 8*8 bytes clockwise
          pattern := 0
          repeat i from 7 to 0
            pattern := pattern << 1
            if (byte[RowBuff + i] & mask)
              pattern |= $01
          _vdpWrite(pattern ^ byte[@XorMask][invert], 0)
          mask := mask >> 1
    else
      pMemSrc := @CharGen8x8 'this chargen is in right row-wise format, just copy
      repeat 128 * 8
        pattern := byte[pMemSrc++]
        _vdpWrite(pattern ^ byte[@XorMask][invert], 0)
      
PRI _fillVdpMem(pVdp, count, value, increment)
  'if increment
  '  _logTrace(String("Fill VDP mem from "), pVdp, String(" to "), pVdp + count - 1, String(" with incrementing value "), value, 2)
  'else
  '  _logTrace(String("Fill VDP mem from "), pVdp, String(" to "), pVdp + count - 1, String(" with constant value "), value, 2)
  'setReg(1, reg[1] & %1011_1111) 'blank screen
  _vdpWrite(pVdp.byte[0], 1) 
  _vdpWrite(%0100_0000 | pVdp.byte[1], 1) 
  repeat count
    _vdpWrite(value.byte[0], 0)
    value += increment
  'setReg(1, reg[1] | %0100_0000) 'show screen

PRI _copyToVdpMem(pVdp, pMain, count)
  '_logTrace(String("Copy "), count, String(" bytes from main memory address "), pMain, String(" to VDP address "), pVdp, 8)
  'setReg(1, reg[1] & %1011_1111) 'blank screen 
  _vdpWrite(pVdp.byte[0], 1) 
  _vdpWrite(%0100_0000 | pVdp.byte[1], 1) 
  repeat count
    _vdpWrite(byte[pMain++], 0)
  'setReg(1, reg[1] | %0100_0000) 'show screen

PRI _copyFromVdpMem(pVdp, pMain, count) |val
  '_logTrace(String("Copy "), count, String(" bytes from VDP address "), pVdp, String(" to main memory address "), pMain, 8)
  'setReg(1, reg[1] & %1011_1111) 'blank screen 
  _vdpWrite(pVdp.byte[0], 1) 
  _vdpWrite(%0000_0000 | pVdp.byte[1], 1) 
  repeat count
    byte[pMain++] := _vdpRead(0)
  'setReg(1, reg[1] | %0100_0000) 'show screen

PRI _setReg(index, value)
  if (index > 7)
    _logError(String("Invalid register number."))
  else 
    reg[index] := value
    _vdpWrite(value, 1)
    _vdpWrite(%1000_0000 | index, 1) 

PRI _interval(cntEnd, cntStart)
  result := cntEnd - cntStart
  if (result < 0)
    result := $7FFF_FFFF + result
  return result 
  
{{ interfacing with VDP chip }}  
PRI _readStatus
  return _vdpRead(1)

PRI _vdpRead(modeVal)
  if (modeVal == 0)             'only wait if reading from vdp memory, not status reg
    _waitForScan
  outa[MODE] := modeVal         'set mode
  outa[nCSW]~~                  'write inactive
  outa[nCSR]~~                  'read inactive
  dira[CD0 .. CD7]~             'data bus is input
  outa[nCSR]~                   'pulse nCSR
  outa[nCSR]~                   'delay
  outa[nCSR]~                   'delay
  result := ina[CD0 .. CD7]
  outa[nCSR]~~
        
PRI _vdpWrite(byteVal, modeVal)
  if (modeVal == 0)             'only wait if writing to vdp memory, not register
  _waitForScan
  outa[MODE] := modeVal         'set mode
  outa[nCSW]~~                  'write inactive
  outa[nCSR]~~                  'read inactive
  dira[CD0 .. CD7]~~            'data bus is output
  outa[CD0 .. CD7] := byteVal 
  outa[nCSW]~                   'pulse nCSW
  outa[nCSW]~                   'delay
  outa[nCSW]~                   'delay
  outa[nCSW]~~
     
PRI _vdpReset
  outa[nReset]~
  waitcnt((clkfreq / 2) + cnt) '500ms
  outa[nReset]~~

PRI _waitForScan
  if ((reg[1] & %0110_0000) == %0110_0000)      'only wait if not blanking and in interrupt mode
    if ((cnt - lastScanCnt) > vdpAccessWindow)
      dira[nInt] := 0           'make sure nInt is input (redundant?)
      repeat
        if (ina[nInt])
          waitpeq(0, |< nInt, 0)  'wait for nInt to go low
        lastStatus := _readStatus
      until (lastStatus & %1000_0000) 'F bit is set, meaning interrupt due to scan line
      lastScanCnt := cnt

{{ various helpers }}
PRI _logCommand(commandString, ellapsedCycles) |stackSize
  if (skipTrace)
    return
  pst.Str(String("TRACE: "))
  pst.Str(commandString)
  pst.Hex(displayMode, 2)
  pst.Str(String(" executed in "))
  pst.Dec(ellapsedCycles / (clkfreq / 1_000_000))
  pst.Str(String(" us."))

  stackSize := STACK_LEN
  repeat
    stackSize--
  while ((stackSize > 0) and (stack[stackSize] == 0))
  pst.Str(String(" Stack watermark is "))
  pst.Dec(stackSize)
  
  pst.Newline

PRI _logSprite(string1, attrAddr, buffAddr)
  if (skipTrace)
    return
  pst.Str(String("TRACE: "))
  pst.Str(string1)
  pst.Hex(attrAddr, 8)
  pst.Str(String(" y= "))
  pst.Hex(byte[buffAddr][0], 2)
  pst.Str(String(" x= "))
  pst.Hex(byte[buffAddr][1], 2)
  pst.Str(String(" name= "))
  pst.Hex(byte[buffAddr][2], 2)
  pst.Str(String(" color= "))
  pst.Hex(byte[buffAddr][3], 2)
  pst.Newline

PRI _logTrace(string1, val1, string2, val2, string3, val3, hexChars)
  if (skipTrace)
    return
  pst.Str(String("TRACE: "))
  pst.Str(string1)
  pst.Hex(val1, 8)
  if (string2)
    pst.Str(string2)
    pst.Hex(val2, 8)
    if (string3)
      pst.Str(string3)
      if (hexChars > 0)
        pst.Hex(val3, hexChars)
      else
        pst.Dec(val3)
  pst.Newline

PRI _logError(string1)
  if (skipTrace)
    return
  pst.Str(String("ERROR: "))
  pst.Str(string1)
  pst.Newline

PRI _prompt(string1, value)
  if (skipTrace)
    return
  pst.Str(string1)
  pst.Hex(value, 8)
  pst.CharIn  
  pst.NewLine

DAT
'See https://github.com/cbmeeks/TMS9918/blob/master/TI-VDP-PRG.pdf
Mode_Graphics1          BYTE $00, $C0, $05, $80, $01, $20, $00, $01
Mode_Graphics2          BYTE $02, $C2, $0E, $FF, $03, $76, $03, $0F
Mode_Multicolor         BYTE $00, $CB, $05, $00, $01, $20, $00, $04
Mode_Text               BYTE $00, $D0, $02, $00, $00, $20, $00, $F5

RowBuff       BYTE 0[40]        'used for scrolling
SpriteBuff    BYTE 0[4]         'used to read/update sprite
XorMask       BYTE 0, $FF
OrMask        BYTE $80, $40, $20, $10, $08, $04, $02, $01
AndMask       BYTE $7F, $BF, $DF, $EF, $F7, $FB, $FD, $FE

'First 16 "best" from TI-99/4A "TI Extended Basic Manual" p. 200 ((c) Texas Instruments, 1981)
GoodContrastColorsTable
BYTE BLACK << 4 | CYAN
BYTE  BLACK << 4 | DARKRED
BYTE  BLACK << 4 | LIGHTBLUE
BYTE  BLACK << 4 | MEDIUMGREEN
BYTE  DARKBLUE << 4 | CYAN
BYTE  DARKBLUE << 4 | LIGHTBLUE
BYTE  DARKBLUE << 4 | MAGENTA
BYTE  DARKGREEN << 4 | CYAN
BYTE  DARKGREEN << 4 | GRAY
BYTE  DARKGREEN << 4 | LIGHTYELLOW
BYTE  DARKRED << 4 | GRAY
BYTE  DARKRED << 4 | LIGHTYELLOW
BYTE  MEDIUMGREEN << 4 | LIGHTYELLOW
BYTE  BLACK << 4 | DARKGREEN
BYTE  BLACK << 4 | GRAY
BYTE  BLACK << 4 | MAGENTA

CharGen8x8 'Based on "Sinclair_S from http://www.rinkydinkelectronics.com/r_fonts.php 
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $00
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $01
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $02
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $03
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $04
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $05
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $06
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $07
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $08
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $09
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $0A
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $0B
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $0C
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $0D
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $0E
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $0F
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $10
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $11
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $12
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $13
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $14
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $15
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $16
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $17
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $18
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $19
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $1A
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $1B
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $1C
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $1D
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $1E
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' $1F
BYTE $00,$00,$00,$00,$00,$00,$00,$00  ' <space>
BYTE $08,$08,$08,$08,$08,$00,$08,$00  ' !
BYTE $14,$14,$00,$00,$00,$00,$00,$00  ' "
BYTE $00,$24,$7E,$24,$24,$7E,$24,$00  ' #
BYTE $10,$7C,$50,$7C,$14,$7C,$10,$00  ' $
BYTE $00,$62,$64,$08,$10,$26,$46,$00  ' %
BYTE $00,$10,$28,$10,$2A,$44,$3A,$00  ' &
BYTE $00,$08,$10,$00,$00,$00,$00,$00  ' '
BYTE $00,$08,$10,$10,$10,$10,$08,$00  ' (
BYTE $00,$10,$08,$08,$08,$08,$10,$00  ' )
BYTE $00,$00,$28,$10,$7C,$10,$28,$00  ' *
BYTE $00,$00,$10,$10,$7C,$10,$10,$00  ' +
BYTE $00,$00,$00,$00,$00,$08,$08,$10  ' ,
BYTE $00,$00,$00,$00,$7C,$00,$00,$00  ' -
BYTE $00,$00,$00,$00,$00,$18,$18,$00  ' .
BYTE $00,$00,$04,$08,$10,$20,$40,$00  ' /
BYTE $00,$78,$8C,$94,$A4,$C4,$78,$00  ' 0
BYTE $00,$60,$A0,$20,$20,$20,$F8,$00  ' 1
BYTE $00,$78,$84,$04,$78,$80,$FC,$00  ' 2
BYTE $00,$78,$84,$18,$04,$84,$78,$00  ' 3
BYTE $00,$10,$30,$50,$90,$FC,$10,$00  ' 4
BYTE $00,$FC,$80,$F8,$04,$84,$78,$00  ' 5
BYTE $00,$78,$80,$F8,$84,$84,$78,$00  ' 6
BYTE $00,$FC,$04,$08,$10,$20,$20,$00  ' 7
BYTE $00,$78,$84,$78,$84,$84,$78,$00  ' 8
BYTE $00,$78,$84,$84,$7C,$04,$78,$00  ' 9
BYTE $00,$00,$00,$10,$00,$00,$10,$00  ' :
BYTE $00,$00,$10,$00,$00,$10,$10,$20  ' ;
BYTE $00,$00,$08,$10,$20,$10,$08,$00  ' <
BYTE $00,$00,$00,$7C,$00,$7C,$00,$00  ' =
BYTE $00,$00,$20,$10,$08,$10,$20,$00  ' >
BYTE $00,$3C,$42,$04,$08,$00,$08,$00  ' ?
BYTE $00,$3C,$4A,$56,$5E,$40,$3C,$00  ' @
BYTE $00,$78,$84,$84,$FC,$84,$84,$00  ' A
BYTE $00,$F8,$84,$F8,$84,$84,$F8,$00  ' B
BYTE $00,$78,$84,$80,$80,$84,$78,$00  ' C
BYTE $00,$F0,$88,$84,$84,$88,$F0,$00  ' D
BYTE $00,$FC,$80,$F8,$80,$80,$FC,$00  ' E
BYTE $00,$FC,$80,$F8,$80,$80,$80,$00  ' F
BYTE $00,$78,$84,$80,$9C,$84,$78,$00  ' G
BYTE $00,$84,$84,$FC,$84,$84,$84,$00  ' H
BYTE $00,$7C,$10,$10,$10,$10,$7C,$00  ' I
BYTE $00,$04,$04,$04,$84,$84,$78,$00  ' J
BYTE $00,$88,$90,$E0,$90,$88,$84,$00  ' K
BYTE $00,$80,$80,$80,$80,$80,$FC,$00  ' L
BYTE $00,$84,$CC,$B4,$84,$84,$84,$00  ' M
BYTE $00,$84,$C4,$A4,$94,$8C,$84,$00  ' N
BYTE $00,$78,$84,$84,$84,$84,$78,$00  ' O
BYTE $00,$F8,$84,$84,$F8,$80,$80,$00  ' P
BYTE $00,$78,$84,$84,$A4,$94,$78,$00  ' Q
BYTE $00,$F8,$84,$84,$F8,$88,$84,$00  ' R
BYTE $00,$78,$80,$78,$04,$84,$78,$00  ' S
BYTE $00,$FE,$10,$10,$10,$10,$10,$00  ' T
BYTE $00,$84,$84,$84,$84,$84,$78,$00  ' U
BYTE $00,$84,$84,$84,$84,$48,$30,$00  ' V
BYTE $00,$84,$84,$84,$84,$B4,$48,$00  ' W
BYTE $00,$84,$48,$30,$30,$48,$84,$00  ' X
BYTE $00,$82,$44,$28,$10,$10,$10,$00  ' Y
BYTE $00,$FC,$08,$10,$20,$40,$FC,$00  ' Z
BYTE $00,$38,$20,$20,$20,$20,$38,$00  ' [
BYTE $00,$00,$40,$20,$10,$08,$04,$00  ' <backslash>
BYTE $00,$38,$08,$08,$08,$08,$38,$00  ' ]
BYTE $00,$10,$38,$54,$10,$10,$10,$00  ' ^
BYTE $00,$00,$00,$00,$00,$00,$00,$FE  ' _
BYTE $3C,$42,$99,$A1,$A1,$99,$42,$3C  ' `
BYTE $00,$00,$38,$04,$3C,$44,$3C,$00  ' a
BYTE $00,$40,$40,$78,$44,$44,$78,$00  ' b
BYTE $00,$00,$1C,$20,$20,$20,$1C,$00  ' c
BYTE $00,$04,$04,$3C,$44,$44,$3C,$00  ' d
BYTE $00,$00,$38,$44,$78,$40,$3C,$00  ' e
BYTE $00,$0C,$10,$18,$10,$10,$10,$00  ' f
BYTE $00,$00,$3E,$42,$42,$3E,$02,$3C  ' g
BYTE $00,$40,$40,$78,$44,$44,$44,$00  ' h
BYTE $00,$08,$00,$18,$08,$08,$1C,$00  ' i
BYTE $00,$04,$00,$04,$04,$04,$24,$18  ' j
BYTE $00,$40,$50,$60,$60,$50,$48,$00  ' k
BYTE $00,$10,$10,$10,$10,$10,$0C,$00  ' l
BYTE $00,$00,$68,$54,$54,$54,$54,$00  ' m
BYTE $00,$00,$78,$44,$44,$44,$44,$00  ' n
BYTE $00,$00,$38,$44,$44,$44,$38,$00  ' o
BYTE $00,$00,$78,$44,$44,$78,$40,$40  ' p
BYTE $00,$00,$3C,$44,$44,$3C,$04,$06  ' q
BYTE $00,$00,$1C,$20,$20,$20,$20,$00  ' r
BYTE $00,$00,$38,$40,$38,$04,$78,$00  ' s
BYTE $00,$10,$38,$10,$10,$10,$0C,$00  ' t
BYTE $00,$00,$44,$44,$44,$44,$38,$00  ' u
BYTE $00,$00,$44,$44,$28,$28,$10,$00  ' v
BYTE $00,$00,$44,$54,$54,$54,$28,$00  ' w
BYTE $00,$00,$44,$28,$10,$28,$44,$00  ' x
BYTE $00,$00,$44,$44,$44,$3C,$04,$38  ' y
BYTE $00,$00,$7C,$08,$10,$20,$7C,$00  ' z
BYTE $00,$1C,$10,$60,$10,$10,$1C,$00  ' {
BYTE $00,$10,$10,$10,$10,$10,$10,$00  ' |
BYTE $00,$70,$10,$0C,$10,$10,$70,$00  ' }
BYTE $00,$14,$28,$00,$00,$00,$00,$00  ' ~
BYTE $00,$14,$28,$00,$00,$00,$00,$00  ' $7F

CharGen5x7 'Adapted from http://www.noritake-itron.com/Softview/fontsavr.htm
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
BYTE $00, $00, $00, $00, $00, $00, $00, $F2, $00, $00
BYTE $00, $E0, $00, $E0, $00, $28, $FE, $28, $FE, $28
BYTE $24, $54, $FE, $54, $48, $C4, $C8, $10, $26, $46
BYTE $6C, $92, $AA, $44, $0A, $00, $A0, $C0, $00, $00
BYTE $00, $38, $44, $82, $00, $00, $82, $44, $38, $00
BYTE $28, $10, $7C, $10, $28, $10, $10, $7C, $10, $10
BYTE $00, $0A, $0C, $00, $00, $10, $10, $10, $10, $10
BYTE $00, $06, $06, $00, $00, $04, $08, $10, $20, $40
BYTE $7C, $8A, $92, $A2, $7C, $00, $42, $FE, $02, $00
BYTE $42, $86, $8A, $92, $62, $84, $82, $A2, $D2, $8C
BYTE $18, $28, $48, $FE, $08, $E4, $A2, $A2, $A2, $9C
BYTE $3C, $52, $92, $92, $0C, $80, $8E, $90, $A0, $C0
BYTE $6C, $92, $92, $92, $6C, $60, $92, $92, $94, $78
BYTE $00, $6C, $6C, $00, $00, $00, $6A, $6C, $00, $00
BYTE $10, $28, $44, $82, $00, $28, $28, $28, $28, $28
BYTE $00, $82, $44, $28, $10, $40, $80, $8A, $90, $60
BYTE $4C, $92, $9E, $82, $7C, $7E, $88, $88, $88, $7E
BYTE $FE, $92, $92, $92, $6C, $7C, $82, $82, $82, $44
BYTE $FE, $82, $82, $44, $38, $FE, $92, $92, $92, $82
BYTE $FE, $90, $90, $90, $80, $7C, $82, $92, $92, $5E
BYTE $FE, $10, $10, $10, $FE, $00, $82, $FE, $82, $00
BYTE $04, $02, $82, $FC, $80, $FE, $10, $28, $44, $82
BYTE $FE, $02, $02, $02, $02, $FE, $40, $30, $40, $FE
BYTE $FE, $20, $10, $08, $FE, $7C, $82, $82, $82, $7C
BYTE $FE, $90, $90, $90, $60, $7C, $82, $8A, $84, $7A
BYTE $FE, $90, $98, $94, $62, $62, $92, $92, $92, $8C
BYTE $80, $80, $FE, $80, $80, $FC, $02, $02, $02, $FC
BYTE $F8, $04, $02, $04, $F8, $FC, $02, $0C, $02, $FC
BYTE $C6, $28, $10, $28, $C6, $E0, $10, $0E, $10, $E0
BYTE $86, $8A, $92, $A2, $C2, $00, $FE, $82, $82, $00
BYTE $40, $20, $10, $08, $04, $00, $82, $82, $FE, $00
BYTE $20, $40, $80, $40, $20, $02, $02, $02, $02, $02
BYTE $00, $80, $40, $20, $00, $04, $2A, $2A, $2A, $1E
BYTE $FE, $12, $12, $12, $0C, $1C, $22, $22, $22, $22
BYTE $0C, $12, $12, $12, $FE, $1C, $2A, $2A, $2A, $1A
BYTE $00, $10, $7E, $90, $40, $12, $2A, $2A, $2A, $3C
BYTE $FE, $10, $10, $10, $0E, $00, $00, $5E, $00, $00
BYTE $04, $02, $02, $BC, $00, $00, $FE, $08, $14, $22
BYTE $00, $82, $FE, $02, $00, $3E, $20, $1C, $20, $3E
BYTE $3E, $10, $20, $20, $1E, $1C, $22, $22, $22, $1C
BYTE $3E, $28, $28, $28, $10, $10, $28, $28, $28, $3E
BYTE $3E, $10, $20, $20, $10, $12, $2A, $2A, $2A, $24
BYTE $20, $20, $FC, $22, $24, $3C, $02, $02, $02, $3C
BYTE $38, $04, $02, $04, $38, $3C, $02, $0C, $02, $3C
BYTE $22, $14, $08, $14, $22, $20, $12, $0C, $10, $20
BYTE $22, $26, $2A, $32, $22, $00, $10, $6C, $82, $82
BYTE $00, $00, $EE, $00, $00, $82, $82, $6C, $10, $00
BYTE $20, $40, $40, $40, $80, $A8, $68, $3E, $68, $A8
BYTE $BE, $2A, $2A, $2A, $A2, $00, $20, $50, $A0, $00
BYTE $04, $22, $7C, $A0, $40, $84, $FC, $04, $00, $20
BYTE $FE, $02, $02, $12, $02, $1C, $22, $14, $08, $36
BYTE $4E, $3E, $60, $40, $40, $0C, $12, $52, $B2, $1C
BYTE $08, $1C, $2A, $2A, $2A, $F8, $40, $40, $3C, $02
BYTE $7C, $92, $92, $7C, $00, $42, $44, $38, $04, $02
BYTE $20, $3E, $20, $3E, $22, $10, $20, $3C, $22, $20
BYTE $18, $24, $7E, $24, $18, $1C, $22, $0C, $22, $1C
BYTE $82, $C6, $AA, $92, $82, $3A, $46, $40, $46, $3A
BYTE $54, $54, $54, $54, $54, $44, $28, $10, $28, $44
BYTE $10, $10, $54, $10, $10, $00, $70, $88, $88, $70
BYTE $60, $90, $8A, $80, $40, $FE, $FE, $92, $92, $92
BYTE $0A, $1A, $2A, $4A, $8A, $8A, $4A, $2A, $1A, $0A
BYTE $28, $2C, $38, $68, $28, $04, $FE, $80, $80, $80
BYTE $4C, $92, $92, $7C, $00, $04, $02, $7C, $80, $40
BYTE $38, $44, $38, $44, $38, $AA, $54, $AA, $54, $AA
BYTE $00, $00, $00, $00, $00, $00, $00, $BE, $00, $00
BYTE $38, $44, $FE, $44, $00, $12, $7E, $92, $92, $42
BYTE $BA, $44, $44, $44, $BA, $A8, $68, $3E, $68, $A8
BYTE $00, $00, $EE, $00, $00, $50, $AA, $AA, $AA, $14
BYTE $00, $80, $00, $80, $00, $7C, $BA, $AA, $AA, $7C
BYTE $12, $AA, $AA, $AA, $7A, $10, $28, $54, $AA, $44
BYTE $80, $80, $80, $80, $C0, $00, $00, $00, $00, $00
BYTE $7C, $AA, $BA, $82, $7C, $80, $80, $80, $80, $80
BYTE $00, $E0, $A0, $E0, $00, $22, $22, $FA, $22, $22
BYTE $00, $48, $98, $A8, $48, $00, $00, $A8, $A8, $70
BYTE $00, $00, $40, $80, $00, $04, $F8, $10, $10, $E0
BYTE $60, $FE, $80, $FE, $80, $00, $00, $10, $10, $00
BYTE $08, $00, $02, $04, $00, $00, $48, $F8, $08, $00
BYTE $00, $E8, $A8, $E8, $00, $44, $AA, $54, $28, $10
BYTE $F0, $04, $0C, $14, $2E, $F0, $00, $12, $26, $1A
BYTE $FE, $FE, $FE, $FE, $FE, $0C, $12, $A2, $02, $04
BYTE $1E, $A8, $68, $28, $1E, $1E, $28, $68, $A8, $1E
BYTE $1E, $A8, $A8, $A8, $1E, $9E, $A8, $A8, $A8, $9E
BYTE $9E, $28, $28, $28, $9E, $1E, $68, $A8, $68, $1E
BYTE $7E, $90, $FE, $92, $92, $70, $8A, $8C, $88, $88
BYTE $3E, $AA, $6A, $2A, $22, $3E, $2A, $6A, $AA, $22
BYTE $3E, $AA, $AA, $AA, $22, $BE, $2A, $2A, $2A, $A2
BYTE $00, $A2, $7E, $22, $00, $00, $22, $7E, $A2, $00
BYTE $00, $A2, $BE, $A2, $00, $00, $A2, $3E, $A2, $00
BYTE $10, $FE, $92, $82, $7C, $BE, $90, $88, $84, $BE
BYTE $1C, $A2, $62, $22, $1C, $1C, $22, $62, $A2, $1C
BYTE $1C, $A2, $A2, $A2, $1C, $9C, $A2, $A2, $A2, $9C
BYTE $9C, $22, $22, $22, $9C, $44, $28, $10, $28, $44
BYTE $3A, $4C, $54, $64, $B8, $3C, $82, $42, $02, $3C
BYTE $3C, $02, $42, $82, $3C, $3C, $82, $82, $82, $3C
BYTE $BC, $02, $02, $02, $BC, $60, $10, $4E, $90, $60
BYTE $FE, $44, $44, $44, $38, $7E, $A4, $A4, $58, $00
BYTE $04, $AA, $6A, $2A, $1E, $04, $2A, $6A, $AA, $1E
BYTE $04, $AA, $AA, $AA, $1E, $84, $AA, $AA, $AA, $9E
BYTE $04, $AA, $2A, $AA, $1E, $04, $6A, $AA, $6A, $1E
BYTE $2E, $2A, $1C, $2A, $3A, $30, $4A, $4C, $48, $00
BYTE $1C, $AA, $6A, $2A, $1A, $1C, $2A, $6A, $AA, $1A
BYTE $1C, $AA, $AA, $AA, $1A, $1C, $AA, $2A, $AA, $1A
BYTE $00, $80, $5E, $00, $00, $00, $00, $5E, $80, $00
BYTE $00, $40, $5E, $40, $00, $00, $40, $1E, $40, $00
BYTE $0C, $12, $52, $B2, $1C, $BE, $90, $A0, $A0, $9E
BYTE $0C, $92, $52, $12, $0C, $0C, $12, $52, $92, $0C
BYTE $0C, $52, $52, $52, $0C, $4C, $52, $52, $52, $4C
BYTE $0C, $52, $12, $52, $0C, $10, $10, $10, $54, $10
BYTE $18, $26, $3C, $64, $18, $1C, $82, $42, $02, $1C
BYTE $1C, $02, $42, $82, $1C, $1C, $42, $42, $42, $1C
BYTE $1C, $42, $02, $42, $1C, $20, $12, $4C, $90, $20
BYTE $FE, $48, $48, $30, $00, $20, $92, $0C, $90, $20
         