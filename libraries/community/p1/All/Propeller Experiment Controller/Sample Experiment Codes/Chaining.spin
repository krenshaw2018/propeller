{{

┌────────────────────────────────────────────┐
│ Chaining                                   │
│ Author: Christopher A Varnon               │
│ Created: 12-20-2012                        │
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  This program provides a reinforcer only when responses are emitted in a specific order.
  If two response devices are used, the subject must activate the response1 device then the response2 device to receive reinforcement.
  Three response devices can also be used so that the subject must activate all three response devices in the correct order.
  Reinforcement is not provided if it is already available.

  The user will need to specify the pins used for all response devices, the reinforcement, the house lights, the and SD card.
  The user will also need to specify the duration of the session and the duration of reinforcement.

  Comments and descriptions of the code are provided within brackets and following quotation marks.

}}

CON
  '' This block of code is called the CONSTANT block. Here constants are defined that will never change during the program.
  '' The constant block is useful for defining constants that will be used often in the program. It can make the program much more readable.

  '' The following two lines set the clock mode.
  '' This enables the propeller to run quickly and accurately.
  '' Every experiment program will need to set the clock mode like this.
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  '' The following four constants are the SD card pins.
  '' Replace these values with the appropriate pin numbers for your device.
  DO  = 0
  CLK = 1
  DI  = 2
  CS  = 3

  '' Replace the following values with whatever is desired for your experiment.
  '' Note that underscores are used in place of commas.
  '' The underscores are unnecessary and do not change the program, they only make the numbers easier to read.
  UseThreeResponses   = true                                                    ' Set to true to use a three response chain. Set to false to ignore response device 3 and only use a 2 response chain.
  SessionLength       = 10_000                                                  ' The length of the session in milliseconds.
  ReinforcementLength = 2_000                                                   ' The length of reinforcement in milliseconds.

  '' Replace the following values with the pins connected to the devices.
  Response1Pin       = 24
  Response2Pin       = 28
  Response3Pin       = 25
  ReinforcementPin   = 23
  HouseLightPin      = 17                                                       ' The house lights will activate only while the experiment is running. Leave the pin disconnected if house lights control is not needed.
  DiagnosticLEDPin   = 16                                                       ' The LED will turn on after the experiment is complete and it is safe to remove the SD card. Leave the pin disconnected if a diagnostic LED is not needed.

  '' Input Event States
  '' These states are named in the constant block to make the program more readable.
  Off     = 0                                                                   ' Off means that nothing is detected on an input.    Example: The rat is not pressing the lever.
  Onset   = 1                                                                   ' Onset means that the input was just activated.     Example: The rat just pressed the lever.
  On      = 2                                                                   ' On means that the input has been active a while.   Example: The rat pressed the lever recently and is still pressing it.
  Offset  = 3                                                                   ' Offset means that the input was just deactivated.  Example: The rat was pressing the lever, but it just stopped.

  '' Output Event States
  OutOn   = 1                                                                   ' The output is on.
  OutOff  = 3                                                                   ' The output is off.

VAR
  '' The VAR or Variable block is used to define variables that will change during the program.
  '' Variables are different from constants because variables can change, while constants cannot.
  '' The variables only be named in the variable space. They will be assigned values later.
  '' The size of a variable is also assigned in the VAR block.
  '' Byte variables can range from 0-255 and are best for values you know will be very small.
  '' Word variables are larger. They range from 0-65,535. Word variables can also be used to save the location of string (text) values in memory.
  '' Long variables are the largest and range from -2,147,483,648 to +2,147,483,647. Most variables experiments use will be longs.
  '' As there is limited space on the propeller chip, it is beneficial to use smaller sized variables when possible.
  '' It is unlikely that an experiment will use the entire memory of the propeller chip.

  word Response1Name                                                            ' This variable will refer to the text description of the response1 event that will be saved to the data file.
  word Response2Name                                                            ' This variable will refer to the text description of the response2 event that will be saved to the data file.
  word Response3Name                                                            ' This variable will refer to the text description of the response3 event that will be saved to the data file.
  word ReinforcementName                                                        ' This variable will refer to the text description of the reinforcement event that will be saved to the data file.

  long Start                                                                    ' This variable will contain the starting time of the experiment. All other times will be compared to this time.
  long ReinforcementStart                                                       ' This variable will contain the starting time of each reinforcement. This is needed to know when to stop delivering the reinforcement.

  byte Response1First                                                           ' This variable notes if response 1 occurred first in a chain.
  byte Response2Second                                                          ' This variable notes if response 2 occurred second in a chain.

OBJ
  '' The OBJ or Object block is used to declare objects that will be used by the program.
  '' These objects allow the current program to use code from other files.
  '' This keeps programs organized and makes it easier to share common code between multiple programs.
  '' Additionally, using objects written by others saves time and allows access to complicated functions that may be difficult to create.
  '' The objects are given short reference names. These abbreviations will be used to refer to code in the objects.

  '' The Experimental Functions object is the master object for experiments. It is responsible for keeping precise time, as well as saving data.
  exp : "Experimental_Functions"                                                ' Loads experimental functions.

  '' The Experimental Event object works in tandem with Experimental Functions.
  '' Each Experimental Event object is dedicated to keeping track of a specific event, and passing this information along to Experimental Functions.
  '' Each event in an experiment such as key pecks, stimulus lights, tones, and reinforcement uses its own experimental event object.
  Response1     : "Experimental_Event"                                          ' Loads response1 as an experimental event.
  Response2     : "Experimental_Event"                                          ' Loads response2 as an experimental event.
  Response3     : "Experimental_Event"                                          ' Loads response3 as an experimental event.
  Reinforcement : "Experimental_Event"                                          ' Loads reinforcement as an experimental event.
  HouseLight    : "Experimental_Event"                                          ' Loads houselight as an experimental event.

PUB Main
  '' The PUB or Public block is used to define code that can be used in a program or by other programs.
  '' The name listed after PUB is the name of the method.
  '' The program always starts with the first public method. Commonly this method is named "Main."
  '' The program will only run code in the first method unless it is explicitly told to go to another method.

  '' The statement "SetVariables" sets all the variables using a separate method. Scroll down to the SetVariables method to read the code.
  '' A separate method is not needed to set the variables, it can be done in the main method.
  '' However, dividing a program into sections can make it much easier to read.
  exp.startexperiment(DO,CLK,DI,CS)                                             ' Launches all the code in experimental functions related to timing and saving data. Also provides the SD card pins for saving data.
  SetVariables                                                                  ' Implements the setvariables method. Scroll down to read the code.
  houselight.turnon                                                             ' Turns on the house lights.
  start:=exp.time(0)                                                            ' Sets the variable 'start' to time(0) or the time since 0 - the present.
                                                                                ' In other words, the experiment started now.

  repeat until exp.time(start)>sessionlength                                    ' Repeats the indented code until time(start), or time since the experiment started, is greater than the session length.
                                                                                ' In other words, repeat until the session length has been reached.

    '' The next lines of code is the basis for conducting experiments using experimental functions.
    '' When in a repeat loop, this code constantly checks the state of an input device.
    '' If anything has changed since the last time it checked, data is automatically recorded.
    '' In this way, the time of the onset and of the offset of every event can be recorded easily.
    exp.record(response1.detect, response1.ID, exp.time(start))                 ' Detect the state of the first response device and record the state if it has changed.
    exp.record(response2.detect, response2.ID, exp.time(start))                 ' Detect the state of the second response device and record the state if it has changed.
    exp.record(response3.detect, response3.ID, exp.time(start))                 ' Detect the state of the third response device and record the state if it has changed.

    Contingencies                                                               ' Implements the contingencies method. Scroll down to read the code.

    '' This ends the main program loop. The loop will repeat until the session length is over, then drop down to the next line of code.

  '' The session has ended.
  if reinforcement.state==OutOn                                                 ' If the reinforcement is still occurring after the session ended.
    stopreinforcement                                                           ' Stop the reinforcement.

  houselight.turnoff                                                            ' Turns off the house lights.
  exp.stopexperiment                                                            ' Stop the experiment. This line is needed before saving data.

  exp.preparedataoutput                                                         ' Prepares a data.cvs file.
  exp.savedata(response1.ID,response1name)                                      ' Sorts through memory for all occurrences of the response1 event and saves them to the data file.
  exp.savedata(response2.ID,response2name)                                      ' Sorts through memory for all occurrences of the response2 event and saves them to the data file.
  exp.savedata(response3.ID,response3name)                                      ' Sorts through memory for all occurrences of the response2 event and saves them to the data file.
  exp.savedata(reinforcement.ID,reinforcementname)                              ' Sorts through memory for all occurrences of the reinforcement event and saves them to the data file.

  exp.shutdown                                                                  ' Closes all the experiment code.

  dira[DiagnosticLEDPin]:=1                                                     ' Makes the diagnostic LED an output.
  repeat                                                                        ' The program enters an infinite repeat loop to flash the LED.
    !outa[DiagnosticLEDPin]                                                     ' Changes the state of the LED.
    waitcnt(clkfreq/10*5+cnt)                                                   ' Waits .5 seconds.
  ' When the LED starts flashing, it is safe to remove the SD card.

PUB SetVariables
  '' Sets up the experiment variables and events.

  response1name:=string("Response 1")                                           ' This sets the variable response1name to a string. Think of string as a "string of letters."
  response2name:=string("Response 2")                                           ' The name of the response2 event.
  response3name:=string("Response 3")                                           ' The name of the response3 event.
  reinforcementname:=string("Reinforcement")                                    ' The name of the reinforcement event.

  '' The following lines use experimental event code to prepare the events.
  response1.declareinput(response1pin,exp.clockID)                              ' This declares that the experimental event 'response1' described in the OBJ section is an input on the response1 pin.
  response2.declareinput(response2pin,exp.clockID)                              ' This declares that the experimental event 'response2' described in the OBJ section is an input on the response2 pin.
  response3.declareinput(response3pin,exp.clockID)                              ' This declares that the experimental event 'response3' described in the OBJ section is an input on the response3 pin.
  reinforcement.declareoutput(reinforcementpin,exp.clockID)                     ' This declares that the experimental event 'reinforcement' described in the OBJ section is an output on the reinforcement pin.
  houselight.declareoutput(houselightpin,exp.clockID)                           ' This declares that the experimental event 'houselight' described in the OBJ section is an output on the light pin.

PUB Contingencies
  '' The contingencies are implemented in a separate method to increase readability.
  '' Note that the contingencies method is run every program cycle, immediately after the response device is checked.

  if usethreeresponses==true                                                    ' If a three response devices are being used.
    if response1.state==Onset and reinforcement.state==OutOff                   ' If the response1 device was just activated, and the reinforcement is off.
      response1first:=1                                                         ' Note that response1 occurred before response2.

    if response2.state==Onset and reinforcement.state==OutOff                   ' If the response2 device was just activated, and the reinforcement is off.
      if response1first==1                                                      ' If response1 occurred before response2.
        response2second:=1                                                      ' Note that response2 occurred after response1.
      else                                                                      ' If response1 did not occur before response2.
        response1first:=0                                                       ' Note that response1 did not occur first.
        response2second:=0                                                      ' Note that response2 did not occur second.

    if response3.state==Onset and reinforcement.state==OutOff                   ' If the response3 device was just activated, and the reinforcement is off.
      if response1first+response2second==2                                      ' If the first two responses occurred in the correct order.
        StartReinforcement                                                      ' Reinforce. Scroll down to read the reinforce method code.
      response1first:=0                                                         ' Reset the response1first variable.
      response2second:=0                                                        ' Reset the response1first variable.

  else                                                                          ' If only two response devices are being used.
    if response1.state==Onset and reinforcement.state==OutOff                   ' If the response1 device was just activated, and the reinforcement is off.
      response1first:=1                                                         ' Note that response1 occurred before response2.

    if response2.state==Onset and reinforcement.state==OutOff                   ' If the response2 device was just activated, and the reinforcement is off.
      if response1first==1                                                      ' If response1 occurred before response 2.
        StartReinforcement                                                      ' Reinforce. Scroll down to read the reinforce method code.
      response1first:=0                                                         ' Reset the response1first variable.

  if reinforcement.state==OutOn and exp.time(reinforcementstart)=>reinforcementlength   ' If the reinforcement is on, and the reinforcement has been on for more than its maximum duration.
    Stopreinforcement                                                                   ' Stop the reinforcement. Scroll down to read the method.

PUB StartReinforcement
  '' This method provides reinforcement, and records the onset of reinforcement.

  exp.record(reinforcement.turnon, reinforcement.ID, exp.time(start))           ' Starts and records the reinforcement.
  reinforcementstart:=exp.time(start)                                           ' Notes that reinforcement started now.

PUB StopReinforcement
  '' This method ends the reinforcement, and records the offset of reinforcement.

  exp.record(reinforcement.turnoff, reinforcement.ID, exp.time(start))          ' Stops and records the reinforcement.

DAT
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
