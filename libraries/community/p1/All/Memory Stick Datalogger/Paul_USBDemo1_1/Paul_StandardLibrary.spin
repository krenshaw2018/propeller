'' ******************************************
'' *          Paul Deffenbaugh's            *
'' *       Standard Function Library        *
'' ******************************************
''
'' http://paul.bluearray.net
''
'' Created January 31, 2008
'' Edited March 8, 2008

'std           : "Paul_StandardLibrary"       ' Paul's Standard Library   

'------General Constants------------
CON
  LF            = 10                                    ' line feed
  CR            = 13                                    ' carriage return
  ESC           = 27


VAR
  long lTemp
  byte bTemp
  byte tempstr[16]
  
'--------------------------------------------------------
'------------------------TIME----------------------------
'--------------------------------------------------------
PUB pauses(time) | clocks              '' Pause for number of seconds
  if time > 0
    clocks := (clkfreq * time)
    waitcnt(clocks + cnt)

PUB pausems(time)
  pause(time)
  
PUB pause(time) | clocks                 '' Pause for number of milliseconds
  if time > 0
    clocks := ((clkfreq / 1000) * time)
    waitcnt(clocks + cnt)
        
PUB pauseus(time) | clocks               '' Pause for number of microseconds     
  if time > 0
    clocks := ((clkfreq / 1_000_000) * time)
    waitcnt(clocks + cnt)

PUB blink(pin,times,period)
  dira[pin] := 1 ' Output
  repeat times
    outa[pin] := 0 ' Low  (0V)
    pause(period/2)
    outa[pin] := 1 ' High (3.3V)
    pause(period/2) 

PUB freqout(pin,frequency,duration) | period,pulses,clocks,t

  dira[pin] := 1                     ' 0:Input, 1:Output 

  period := 1000000 / frequency                          ' Period in us
  pulses := (duration*1000) / period                     ' Periods required for duration                                         
  clocks := (clkfreq / 1000000 * period)                 ' Half period clocks
                      
  repeat t from 0 to pulses
    outa[pin] := 0                   ' turn on
    waitcnt(clocks + cnt)            ' on time
    outa[pin] := 1                   ' turn off
    waitcnt(clocks + cnt)            ' off time

  dira[pin] := 0                     ' Input 

'--------------------------------------------------------
'---------------------NUMERIC----------------------------
'--------------------------------------------------------
PUB incrementHundredsB(variableAddr,minValue,maxValue) 
  bTemp := ((byte[variableAddr]/100) // 10)             ' Get value to increment or decrement
  byte[variableAddr] -= bTemp * 100                     ' Clear out digit of number
  incrementB(@bTemp,minValue,maxValue)                  ' Perform increment or decrement
  byte[variableAddr] += bTemp * 100                     ' Replace value in correct decimal place

PUB decrementHundredsB(variableAddr,minValue,maxValue) 
  bTemp := ((byte[variableAddr]/100) // 10)             ' Get value to increment or decrement
  byte[variableAddr] -= bTemp * 100                     ' Clear out digit of number
  decrementB(@bTemp,minValue,maxValue)                  ' Perform increment or decrement
  byte[variableAddr] += bTemp * 100                     ' Replace value in correct decimal place

PUB incrementTensB(variableAddr,minValue,maxValue) 
  bTemp := ((byte[variableAddr]/10) // 10)              ' Get value to increment or decrement
  byte[variableAddr] -= bTemp * 10                      ' Clear out digit of number
  incrementB(@bTemp,minValue,maxValue)                  ' Perform increment or decrement
  byte[variableAddr] += bTemp * 10                      ' Replace value in correct decimal place

PUB decrementTensB(variableAddr,minValue,maxValue) 
  bTemp := ((byte[variableAddr]/10) // 10)              ' Get value to increment or decrement
  byte[variableAddr] -= bTemp * 10                      ' Clear out digit of number
  decrementB(@bTemp,minValue,maxValue)                  ' Perform increment or decrement
  byte[variableAddr] += bTemp * 10                      ' Replace value in correct decimal place
  
PUB incrementUnitsB(variableAddr,minValue,maxValue)   
  bTemp := byte[variableAddr] // 10
  byte[variableAddr] -= bTemp  
  incrementB(@bTemp,minValue,maxValue)
  byte[variableAddr] += bTemp

PUB decrementUnitsB(variableAddr,minValue,maxValue)   
  bTemp := byte[variableAddr] // 10
  byte[variableAddr] -= bTemp  
  decrementB(@bTemp,minValue,maxValue)
  byte[variableAddr] += bTemp
     
PUB incrementB(variableAddr,minValue,maxValue)
  byte[variableAddr]++
  if byte[variableAddr] > maxValue
    byte[variableAddr] := minValue

PUB decrementB(variableAddr,minValue,maxValue)
  if byte[variableAddr] == minValue
    byte[variableAddr] := maxValue
  else  
    byte[variableAddr]--

PUB incrementByteByDigit(variableAddr,digit)

  case digit
    1:
      if byte[variableAddr] == 255
        byte[variableAddr] := 250
      else
        incrementUnitsB(variableAddr,0,9)
    2:
      if byte[variableAddr] == 255
        byte[variableAddr] := 205
      else      
        incrementTensB(variableAddr,0,9)
    3:
      if byte[variableAddr] > (155-1)
        byte[variableAddr] -= 100
      else
        incrementHundredsB(variableAddr,0,2)

PUB decrementByteByDigit(variableAddr,digit)
  case digit
    1:
      if byte[variableAddr] == 250
        byte[variableAddr] := 255
      else
        decrementUnitsB(variableAddr,0,9)
    2:
      if byte[variableAddr] == 205
        byte[variableAddr] := 255
      else
        decrementTensB(variableAddr,0,9)
    3:
      if byte[variableAddr] > 55 AND byte[variableAddr] < 100
        byte[variableAddr] += 100
      else
        decrementHundredsB(variableAddr,0,2)
     
'--------------------------------------------------------
'---------------------LONG----------------------------
'--------------------------------------------------------


PUB incrementHundredsL(variableAddr,minValue,maxValue) 
  lTemp := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= lTemp * 100                     ' Clear out digit of number
  incrementL(@lTemp,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += lTemp * 100                     ' Replace value in correct decimal place

PUB decrementHundredsL(variableAddr,minValue,maxValue) 
  lTemp := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= lTemp * 100                     ' Clear out digit of number
  decrementL(@lTemp,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += lTemp * 100                     ' Replace value in correct decimal place
  
PUB incrementTensL(variableAddr,minValue,maxValue) 
  lTemp := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= lTemp * 10                      ' Clear out digit of number
  incrementL(@lTemp,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += lTemp * 10                      ' Replace value in correct decimal place
 
PUB decrementTensL(variableAddr,minValue,maxValue) 
  lTemp := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= lTemp * 10                      ' Clear out digit of number
  decrementL(@lTemp,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += lTemp * 10                      ' Replace value in correct decimal place

PUB incrementUnitsL(variableAddr,minValue,maxValue)   
  lTemp := long[variableAddr] // 10
  long[variableAddr] -= lTemp  
  incrementL(@lTemp,minValue,maxValue)
  long[variableAddr] += lTemp

PUB decrementUnitsL(variableAddr,minValue,maxValue)   
  lTemp := long[variableAddr] // 10
  long[variableAddr] -= lTemp  
  decrementL(@lTemp,minValue,maxValue)
  long[variableAddr] += lTemp
   
PUB incrementL(variableAddr,minValue,maxValue)
  long[variableAddr]++
  if long[variableAddr] > maxValue
    long[variableAddr] := minValue

    
PUB decrementL(variableAddr,minValue,maxValue)
  long[variableAddr]--
  if long[variableAddr] < minValue
    long[variableAddr] := maxValue

PUB range(variableAddr,minValue,maxValue,defaultValue)
  if (long[variableAddr] < minValue) OR (long[variableAddr] > maxValue)
    long[variableAddr] := defaultValue

'PUB isNum(char)
'  if char < "0" or char > "9"
'    return false
'  else
'    return true    


{ 
'--------------------------------------------------------
'---------------------NUMERIC----------------------------
'--------------------------------------------------------


PUB incrementHundredsB(variableAddr,minValue,maxValue,totalMax) | value
  value := ((byte[variableAddr]/10) // 10)              ' Get value to increment or decrement
  byte[variableAddr] -= value * 100                     ' Clear out digit of number
  incrementB(@value,minValue,maxValue)                   ' Perform increment or decrement
  byte[variableAddr] += value * 100                     ' Replace value in correct decimal place
  if byte[variableAddr] > totalMax
    byte[variableAddr] := totalMax

PUB decrementHundredsB(variableAddr,minValue,maxValue,totalMax) | value
  value := ((byte[variableAddr]/10) // 10)              ' Get value to increment or decrement
  byte[variableAddr] -= value * 100                     ' Clear out digit of number
  decrementB(@value,minValue,maxValue)                   ' Perform increment or decrement
  byte[variableAddr] += value * 100                     ' Replace value in correct decimal place
  if byte[variableAddr] > totalMax
    byte[variableAddr] := totalMax
  
PUB incrementTensB(variableAddr,minValue,maxValue,totalMax) | value
  value := ((byte[variableAddr]/10) // 10)              ' Get value to increment or decrement
  byte[variableAddr] -= value * 10                      ' Clear out digit of number
  incrementB(@value,minValue,maxValue)                   ' Perform increment or decrement
  byte[variableAddr] += value * 10                      ' Replace value in correct decimal place
  if byte[variableAddr] > totalMax
    byte[variableAddr] := totalMax

PUB decrementTensB(variableAddr,minValue,maxValue,totalMax) | value
  value := ((byte[variableAddr]/10) // 10)              ' Get value to increment or decrement
  byte[variableAddr] -= value * 10                      ' Clear out digit of number
  decrementB(@value,minValue,maxValue)                   ' Perform increment or decrement
  byte[variableAddr] += value * 10                      ' Replace value in correct decimal place
  if byte[variableAddr] > totalMax
    byte[variableAddr] := totalMax
  
PUB incrementUnitsB(variableAddr,minValue,maxValue,totalMax) | value  
  value := byte[variableAddr] // 10
  byte[variableAddr] -= value  
  incrementB(@value,minValue,maxValue)
  byte[variableAddr] += value
  if byte[variableAddr] > totalMax
    byte[variableAddr] := totalMax

PUB decrementUnitsB(variableAddr,minValue,maxValue,totalMax) | value  
  value := byte[variableAddr] // 10
  byte[variableAddr] -= value  
  decrementB(@value,minValue,maxValue)
  byte[variableAddr] += value
  if byte[variableAddr] > totalMax
    byte[variableAddr] := totalMax
     
PUB incrementB(variableAddr,minValue,maxValue)
  byte[variableAddr]++
  if byte[variableAddr] > maxValue
    byte[variableAddr] := minValue

PUB decrementB(variableAddr,minValue,maxValue)
  byte[variableAddr]--
  if byte[variableAddr] < minValue
    byte[variableAddr] := maxValue
    
'--------------------------------------------------------
'---------------------LONG----------------------------
'--------------------------------------------------------


PUB incrementHundredsL(variableAddr,minValue,maxValue,totalMax) | value
  value := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= value * 100                     ' Clear out digit of number
  incrementL(@value,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += value * 100                     ' Replace value in correct decimal place
  if long[variableAddr] > totalMax
    long[variableAddr] := totalMax

PUB decrementHundredsL(variableAddr,minValue,maxValue,totalMax) | value
  value := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= value * 100                     ' Clear out digit of number
  decrementL(@value,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += value * 100                     ' Replace value in correct decimal place
  if long[variableAddr] > totalMax
    long[variableAddr] := totalMax
      
PUB incrementTensL(variableAddr,minValue,maxValue,totalMax) | value
  value := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= value * 10                      ' Clear out digit of number
  incrementL(@value,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += value * 10                      ' Replace value in correct decimal place
  if long[variableAddr] > totalMax
    long[variableAddr] := totalMax
    
PUB decrementTensL(variableAddr,minValue,maxValue,totalMax) | value
  value := ((long[variableAddr]/10) // 10)              ' Get value to increment or decrement
  long[variableAddr] -= value * 10                      ' Clear out digit of number
  decrementL(@value,minValue,maxValue)                   ' Perform increment or decrement
  long[variableAddr] += value * 10                      ' Replace value in correct decimal place
  if long[variableAddr] > totalMax
    long[variableAddr] := totalMax
      
PUB incrementUnitsL(variableAddr,minValue,maxValue,totalMax) | value  
  value := long[variableAddr] // 10
  long[variableAddr] -= value  
  incrementL(@value,minValue,maxValue)
  long[variableAddr] += value
  if long[variableAddr] > totalMax
    long[variableAddr] := totalMax
    
PUB decrementUnitsL(variableAddr,minValue,maxValue,totalMax) | value  
  value := long[variableAddr] // 10
  long[variableAddr] -= value  
  decrementL(@value,minValue,maxValue)
  long[variableAddr] += value
  if long[variableAddr] > totalMax
    long[variableAddr] := totalMax
         
PUB incrementL(variableAddr,minValue,maxValue)
  long[variableAddr]++
  if long[variableAddr] > maxValue
    long[variableAddr] := minValue

    
PUB decrementL(variableAddr,minValue,maxValue)
  long[variableAddr]--
  if long[variableAddr] < minValue
    long[variableAddr] := maxValue

}

'--------------------------------------------------------
'------------------BYTES OF A LONG-----------------------
'--------------------------------------------------------
{
  longToStore    := std.buildLong(byte0,byte1,byte2,byte3)
  byteToTransmit := std.getByteLong(myLong,whichByte)   ' whichByte = 0,1,2,3

}                           
PUB putByteLong(byte3,byte2,byte1,byte0)

  '' Shift bits to correct position then mask out garbage
  byte0 := ( byte0       ) & $FF
  byte1 := ( byte1 << 8  ) & $FF  
  byte2 := ( byte2 << 16 ) & $FF 
  byte3 := ( byte3 << 24 ) & $FF
                                                                 
  return ( byte3 | byte2 | byte1 | byte0 )

PUB getByteLong(longVariable,whichByte)
  
  return ( longVariable >> (whichByte << 3) ) & $FF

PUB longswap(a,b) | c
  longmove(@c,b,1)         ' b -> c
  longmove(b,a,1)         ' a -> b
  longmove(a,@c,1)         ' c -> a

PUB byteswap(a,b) | c
  bytemove(@c,b,1)         ' b -> c
  bytemove(b,a,1)         ' a -> b
  bytemove(a,@c,1)         ' c -> a

    
'--------------------------------------------------------
'----------------------BITWISE---------------------------
'--------------------------------------------------------
                           
PUB getBit(variableAddr,index) | localCopy

  localCopy := long[variableAddr]

  return ( (localCopy & (1<<index) ) >> index )

PUB setBit(variableAddr,index)
  ' modified 12/12/2008
'  LONG[variableAddr] := LONG[variableAddr] | (1<<index)
  LONG[variableAddr] := LONG[variableAddr] | (|<index)  

PUB clrBit(variableAddr,index)
  LONG[variableAddr] := LONG[variableAddr] & ( !(1<<index) )

PUB toggleBit(variableAddr,index)
  if (getBit(variableAddr,index) == 0)
    setBit(variableAddr,index)
  else
    clrBit(variableAddr,index)

'--------------------------------------------------------
'-------------------String Manipulators------------------
'--------------------------------------------------------
PUB findInString(address,char,number)

  repeat
    if byte[address] == char
      if number == 0
        return address+1
      else
        number--
    elseif byte[address] == 0
      return address
    address++

PUB strcat(baseStr,appendStr)
'' concatinates appendStr onto the end of baseStr
  strcopy(baseStr+strsize(baseStr),appendStr)
  return baseStr

PUB strcatchar(baseStr,appendChar) | ptr
'' concatinates appendChar onto the end of baseStr
  ptr := baseStr + strsize(baseStr)
  byte[ptr++] := appendChar
  byte[ptr] := 0 ' null-terminate
  return baseStr

PUB insertchar(baseStr,char,offset) | baseStrSize, i
  baseStrSize := strsize(baseStr)
  byte[baseStr+baseStrSize+1] := 0 ' null-terminate
  repeat i from (baseStrSize) to (offset)
    byte[baseStr+i+1] := byte[baseStr+i]
  byte[baseStr+offset] := char
  return baseStr

PUB strcopy(destStr,sourceStr) | copied
'' copies sourceStr into destStr
  copied:=strsize(sourceStr)
  bytemove(destStr,sourceStr,copied+1)    ' copies null terminator
  return copied

PUB strclr(inputStr,n)
  bytefill(inputStr,0,n)
  return inputStr

'PUB strcomp(str1,str2)
'' defined in Sp!n language

PUB strcompn(str1,str2,n) | i
  repeat while (byte[str1] <> 0) and (byte[str2]  <> 0) and (i++ < n)
    if byte[str1++] <> byte[str2++]
      return false
  return true      

'PUB strsize(str1)
'' defined in Sp!n language
  
PUB toupper(inputChar)
  if inputChar => "a" and inputChar =< "z"
    inputChar-= "a" - "A" 
  return inputChar
  
PUB strupper(inputStr) | i, length
  length := strsize(inputStr) - 1
  repeat i from 0 to length
    byte[inputStr] := toupper(byte[inputStr])     

'PUB strclr(input)
'  byte[input] := 0
'  return input
'
'PUB strclrn(input,n) | i
'  repeat i from 0 to n
'    byte[input + i] := 0
'  return input

PUB chartostr(inputChar)
'' Used for concatinating characters onto strings
  tempstr[0] := inputChar
  tempstr[1] := 0 ' null-terminate
  return @tempstr

PUB atoi(inputStr) | tempChar,inputStrPtr, number
  inputStrPtr := inputStr
  number := 0
  tempChar := byte[inputStrPtr++]
  repeat while isNum(tempChar)
    number := (number*10) + (tempChar - "0")  
    tempChar := byte[inputStrPtr++]
  return number

PUB hextochar(inputDigit)
  if inputDigit < $00 or inputDigit > $0F
    inputDigit := 0
  if inputDigit < $0A
    return inputDigit + "0"
  else
    return inputDigit - $0A + "A"  

PUB isNum(inputChar)
  return ((inputChar => "0") and (inputChar =< "9"))

PUB isPrintable(inputChar)
  return ((inputChar => " ") and (inputChar =< "~"))
    
'--------------------------------------------------------
'-------------------Format String---------------------
'--------------------------------------------------------
PUB buildString(dest,type,data)
  byte[dest] := 0
  strcat(dest,type) 
  strcat(dest,string(",")) 
  strcat(dest,data) 
'add check summing here
  strcat(dest,string(CR,LF)) 
  return dest
  
'--------------------------------------------------------
'-------------------String Constants---------------------
'--------------------------------------------------------

PUB PaulDeffenbaugh
  return @name
  
PUB dayOfTheWeek(d)
  ' Day (Sun..Sat)
  if (d < 0 OR d > 6)                                   ' If out of range
    d := 7                                              ' ***
  return @DaysOfTheWeek + (d<<2)                         ' Offset by 0,4,8,... by fours

DAT

DaysOfTheWeek byte "Sun",0, "Mon",0, "Tue",0, "Wed",0, "Thu",0, "Fri",0, "Sat",0, "***",0

name          byte "Paul Deffenbaugh",0