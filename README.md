# Intel-Hex-Processing
A parsing library for Intel Hex written in Processing

README:
TO USE:
  Press "Ctrl + R" to run the sketch or press play. Follow the selection process
written on screen. Once you have made your selections, type the string "truth" into
the memory bank selection menu and press enter. The program will then compile your
logic choices and write a hex file. Intermediary outputs, such as the truth table or
results of the logic functions, can be viewed in the console.

To change the name of the intel hex file, change the variable FILENAME found at
the top of the code. 

If you are having trouble starting the program and you are getting a
"font not found error", please be sure to move the data folder associated with
this sketch in to the same folder as the .pde file. They are coupled. All
intel hex outpus will be written to the data folder. 

Most variables and methods one might want to change are tagged with the comment "To Modify:"
So if one is looking to expand the functionality of the program, Ctrl+F that tag and find what you are looking for.


Possible Bug; Wikipedia Article on Intel Hex says the Record Checksum should be calculated using the LSB's two's complement. But then goes on to use the
two least signifigant digits in its calculation instead of the single LSB. The C intel hex lib also seems to use the two LSD checksum calculation method. This all works well now, but then it
would appear wikipedia is broken.
