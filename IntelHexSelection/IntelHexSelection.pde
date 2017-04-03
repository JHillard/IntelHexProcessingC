/*
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
*/

/*  FEATURES:
  Arbitrary Logic Function Execution. Can type any combination of logics: "A0 || A2 && (A0 || A3)"   
              (Note, this arbitrary code execution _may_ be novel to Processing, only ever seen it in Java)
  Switchable chips.
  CSV imports arbitrary truth tables and converts them to Intel Hex, so you don't even have to use the GUI!
  Many Waveform Generation options. Modularized to make it easy to add a new one.
  Easily Editable Filename.
*/  
String FILENAME = "ProcessingCode.hex"; //To Modify: choose your filename;

final String logicFileExtension = ".logic";  
  
//GUI Variables
PFont font;
String selAsk = "Enter Memory Bank: ";
String selMenu ="";
String keyBoardText = "";
String BankSelect ="";
int PinSelect = -1;
String CustomLogic1 = "Cust1"; //To Modify: Add a brief title of your custom logic. These are the Title Strings
String CustomLogic2 = "Cust2";
final int WAVEFORMFRONT = 6; // Determines where to treat selections as waveforms, and where to treat as individual logic.
                             // To Modify: if adding more than the two default custom logics, increment this.
                             // Otherwise it will treat your new logic function as a waveform, and break.

Table WaveformSelection = new Table();
int Logic = -1;
Boolean Confirm = false;
Boolean BackStep = false;
Boolean ProcessSelection = false;
int Menu = 0;
int bg = 190;
int selectTextOffset = 125;


color darkBlue = color(50,55,100);
color white = color(255,255,255);
color highlightColor = color(215,215,255);
//*/
//=====================================================================================================

//Possible Bug; Wikipedia Article on Intel Hex says the Record Checksum should be calculated using the LSB's two's complement. But then goes on to use the
//two least signifigant digits in its calculation instead of the single LSB. The C intel hex lib also seems to use the two LSD checksum calculation method. This all works well now, but then it
//would appear wikipedia is broken.

//Intel Hex Writing Variables


Table table;
//Table WaveformSelection;
int addrSize = 12; //Number of Oscillators + DIP Switches
int outSize = 8; //Number of output pins. WARNING: STATIC. Intel Hex only works with 8-bit outputs.
int[] values = new int[addrSize];
String TruthTableName = "test.csv";
String addrName = "addr";
String outName = "out";
final int NUM_SELECTORS = 4; //number of DIP switches;
final int NUM_BANKS = int(pow(2,NUM_SELECTORS));
final int NUM_OSC = 8;

//Javascript Engine Imports
import javax.script.*;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;


//GUI Variables
import controlP5.*;
import java.util.*;

PImage M27C512;
PImage M2732A;

int defaultColor = 0;
//int defaultColor = 255;

int currentColor = 0;
float currentIncrement = 1;
int flashColor = color(0,160,100);
float flashRate = 0.1;
boolean flashing = false;
boolean firstRun = true;

ControlP5 ChipSelect;
//Logic Function Controller.
ControlP5 logicFunction;
//Selector between logic function and wave generation
ControlP5 programSelection;
// Waveform Generation Controller
ControlP5 waveGen;
//Controller for Pin selections and things that will always appear despite selections.
ControlP5 defaults;
  Textlabel membankSelectText1;
  Textlabel membankSelectText2;
  Textlabel outpinText1;
  Textlabel outpinText2;
//Controller for opening screen. Put tutorial modules or intro text here.
ControlP5 openingScreen;
  Textlabel opening1;
  Textlabel opening2;
  Textlabel opening3;
  Textlabel opening4;
  
ControlP5 EEPROM1;
ControlP5 EEPROM2;
//Various booleans modified by the above controllers. Doesn't communicate to the rest of program. 
boolean EEPROM1_chosen = false;
boolean Membank_0 = false;
boolean Membank_1 = false;
boolean Membank_2 = false;
boolean Membank_3 = false;
boolean outpin_0 = false;
boolean outpin_1 = false;
boolean outpin_2 = false;
boolean outpin_3 = false;
boolean outpin_4 = false;
boolean outpin_5 = false;
boolean outpin_6 = false;
boolean outpin_7 = false;

//Controller Strings. These are Strings used by the rest of the program to determine what the user has selected. 
boolean useLogic = true;
boolean useFunction = false;
String selectedChip = "";
String chip1 = "M27C512";
String chip2 = "M2732A";

final String sinTag = "Sin Wave";
final String cosTag = "Cos Wave";
final String squareTag = "Square Wave";
final String sawTag = "Saw Wave";
String selectedWave = "";

String logicString = "";
String logicPrompt = "Arbitrary Logic Function        Ex: A0 || ( A7&&A3) \nFilenames are entered here.   EX: test.logic";

String membankSelection = "";
String outpinSelection = "";
String logicFunctionTag = "Logic Function";
String waveGenTag = "Waveform Generator";
String selectedProgram = "";

//Misc variables.
int col = color(255);
int prgmState;
boolean beginSynthesis = false;



void controlEvent(ControlEvent theEvent) {
  if(theEvent.isAssignableFrom(Textfield.class)) {
    logicString = theEvent.getStringValue();
    println(logicString);
    //logicFunction.get(Textfield.class,logicPrompt).getText();
     flashing = true;
     beginSynthesis = true; //This is to break the synthesis method out from the button return method, b/c the button method has built in error handling that obfuscates problems with Hex Generation.
     guiGeneratesHex();
  }
}


void setup() {
  
  textSize(16);
  ControlFont cf1 = new ControlFont(createFont("Consolas",13));
  
  
  WaveformSelection.addColumn("Memory Bank", Table.STRING);
  WaveformSelection.addColumn("Pin", Table.STRING);
  WaveformSelection.addColumn("Logic", Table.STRING);

  
  
  size(1280, 700);
  smooth();
  
  M27C512 = loadImage("M27C512.png");
  M2732A = loadImage("M2732A.png");

  EEPROM1 = new ControlP5(this);
  EEPROM1.addToggle(chip1 + "_chosen")
    .setFont(cf1).setPosition(40, 100)
    .setSize(50, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    ;

  openingScreen = new ControlP5(this);
  opening1 = openingScreen.addTextlabel("opening1")
    .setText("Welcome")
    .setFont(cf1).setPosition(width/2, height/2);
    ;
  opening2 = openingScreen.addTextlabel("opening2")
    .setText("SELECT CHIP to get started.")
    .setFont(cf1).setPosition(width/2, height/2 + 15);
    ;
  
    String str = "ABOUT:\nThe HexProcessing project allows EPROMS to be used as a programmable logic device, \n" +
    "or a waveform generator. Use the GUI to assign pins, choose between supported chips,  \n" +
    "and determine logic functions. Aimed at the maker community, this tools allows you to  \n" +
    "repurpose old UV erasable EPROM technology into interesting and useful gadgets. Of particular  \n" +
    "focus is the digital multiplication of oscillators to explore the minute differences  \n"  +
    "of parts-per-million errors present within them.  \n";


  opening3 = openingScreen.addTextlabel("opening3")
    .setText(str)    
    .setFont(cf1).setPosition(width/2, 15);
    ;
    
    str = "HOW TO USE: \n" +
          "By default the filename of the output is ProcessingCode.hex (which may be changed on the first \n" +
          "line of the Processing code). Logic execution from a .logic file allows boolean logic \n" +
          "of arbitrary complexity. The filename foo.logic will create a hex file of foo.hex for your \n" +
          "convienience.  \n\n" +
          
          "The program uses pins A8 through A11 as memory banks to store multiple functions on a \n" +
          "single EPROM. Simply drive the pins high or low to access the different memory bank functions. \n" +
          "All logic must index from the input pins A0 through A7, thus an example logic function might\n" +
          "look like:\n\n" +
          
          "A1 && (A2||A3)^A5 \n\n" +
          
          "All logic used is Javascript boolean logic. \n\n" +
          
          "The demo file test.logic inside of \\data \nmay be opened with a simple text editor.\n" +
          "For instructions on how to input\nlogic files, read the instructions found there. \n\n";

  opening4 = openingScreen.addTextlabel("opening4")
    .setText(str)    
    .setFont(cf1).setPosition(width/2, 15);
    ;
    
  
  opening1.setPosition(width/2-opening1.getWidth()/2, height/2);
  opening2.setPosition(width/2-opening2.getWidth()/2, height/2+15);
  opening3.setPosition(width-opening3.getWidth()/2 - 600, height-125);
  opening4.setPosition(10, 10);
  
  
  defaults = new ControlP5(this);
  defaults.setVisible(false);
        int synthButtonXpos = 950;
        int synthButtonYpos = 600;
        defaults.addButton("SYNTHESIZE_HEX")
            .setValue(0)
            .setFont(cf1).setPosition(synthButtonXpos,synthButtonYpos)
            .setSize(200,40)
            ;
            
        int membankXpos = 175;
        int membankYpos = 210;
        int membankYspace = 20;
        defaults.addToggle("Membank_0")
          .setPosition(membankXpos, membankYpos + membankYspace*1)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("Membank_1")
          .setPosition(membankXpos, membankYpos + membankYspace*2)
          .setSize(50, 20)
          .setValue(true)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("Membank_2")
          .setPosition(membankXpos, membankYpos + membankYspace*3)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("Membank_3")
          .setPosition(membankXpos, membankYpos + membankYspace*4)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        membankSelectText1 = defaults.addTextlabel("membankSelectText1")
          .setText("Select Memory Bank")
          .setFont(cf1).setPosition(membankXpos-40, membankYpos)
          ;
        membankSelectText2 = defaults.addTextlabel("membankSelectText2")
          .setText(membankSelection)
          .setFont(cf1).setPosition(membankXpos+10, membankYpos+membankYspace*5+2)
          ;  
          
        int outpinXpos = 950-350;
        int outpinYpos = 100;
        int outpinYspace = 20;
        defaults.addToggle("outpin_0")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*1)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("outpin_1")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*2)
          .setSize(50, 20)
          .setValue(true)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("outpin_2")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*3)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("outpin_3")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*4)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
          defaults.addToggle("outpin_4")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*5)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("outpin_5")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*6)
          .setSize(50, 20)
          .setValue(true)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("outpin_6")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*7)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        defaults.addToggle("outpin_7")
          .setPosition(outpinXpos, outpinYpos + outpinYspace*8)
          .setSize(50, 20)
          .setValue(false)
          .setCaptionLabel("")
          .setMode(ControlP5.SWITCH)
          ;
        outpinText1 = defaults.addTextlabel("outpinText1")
          .setText("Select Output Pins")
          .setFont(cf1).setPosition(outpinXpos-15, outpinYpos)
          ;
        outpinText2 = defaults.addTextlabel("outpinText2")
          .setText(outpinSelection)
          .setFont(cf1).setPosition(outpinXpos-7, outpinYpos+outpinYspace*9+2)
          ;                                    

          List l2 = Arrays.asList(logicFunctionTag, waveGenTag);
          /* add a ScrollableList, by default it behaves like a DropdownList */
          programSelection = new ControlP5(this);
          programSelection.addScrollableList("Program_Selection")
            .setFont(cf1).setPosition(200, 100)
            .setSize(200, 100)
            .setBarHeight(20)
            .setItemHeight(20)
            .addItems(l2)
            // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
            ;

  EEPROM2 = new ControlP5(this);
  EEPROM2.addToggle("toggle2")
    .setPosition(40, 250)
    .setSize(50, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    ;   


  List l = Arrays.asList(chip1, chip2, "Main Menu");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  ChipSelect = new ControlP5(this);
  ChipSelect.addScrollableList("Chip_Select")
    .setFont(cf1).setPosition(200, 100)
    .setSize(200, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(l)
    .setFont(cf1); //TODO font
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    ;
   
   List l3 = Arrays.asList(sinTag,cosTag,sawTag,squareTag);
  /* add a ScrollableList, by default it behaves like a DropdownList */
  waveGen = new ControlP5(this);
  waveGen.addScrollableList("Wave_Selection")
    .setFont(cf1).setPosition(200, 100)
    .setSize(200, 75)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(l3)
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    ;
   
   
   logicFunction = new ControlP5(this);
   logicFunction.addTextfield(logicPrompt)
     .setFont(cf1).setPosition(200, 100)
     .setSize(200,20)
     .setFocus(true)
     ;  
    
}


void draw() {
  background(defaultColor);
  manageBackground();
  pushMatrix();
  cleanCanvas();
  manageCanvas();
  generateSelectionString();
  popMatrix();
  if(beginSynthesis) guiGeneratesHex();
}
/*
*Monitors Buttons/Text Fields to appropraitely assign control values based on user input. These variables are what
* interfaces the graphics module to the rest of the program.
*/
void generateSelectionString() {
  membankSelection = str(int(Membank_0)) + str(int(Membank_1)) + str(int(Membank_2)) + str(int(Membank_3));
  outpinSelection = str(int(outpin_0)) + str(int(outpin_1)) + str(int(outpin_2)) + str(int(outpin_3)) + str(int(outpin_4)) + str(int(outpin_5)) + str(int(outpin_6)) + str(int(outpin_7));       
  logicString = logicFunction.get(Textfield.class,logicPrompt).getText();
  //println("Bank Selection: " + membankSelection);
  //println("Output Pin Selection: " + outpinSelection);
  //println("Logic String: " + logicString);
}

/*
*Called everytime program is chosen from programming dropdown menu
*/
void Program_Selection(int n){
 println(programSelection.get(ScrollableList.class, "Program_Selection").getItem(n).get("name"));
 selectedProgram = (programSelection.get(ScrollableList.class, "Program_Selection").getItem(n).get("name")).toString(); 
}
/*
*Called everytime chip select is chosen from dropdown menu.  
 */
void Chip_Select(int n) {
  //println( ChipSelect.get(ScrollableList.class, "Chip_Select").getItem(n).get(4));
  println(ChipSelect.get(ScrollableList.class, "Chip_Select").getItem(n).get("name"));
  selectedChip = (ChipSelect.get(ScrollableList.class, "Chip_Select").getItem(n).get("name")).toString();
  if(selectedChip == "Main Menu") selectedChip = "";
}
/*
*Called everytime waveform is chosen from waveform dropdown menu
*/
void Wave_Selection(int n){
 println(waveGen.get(ScrollableList.class, "Wave_Selection").getItem(n).get("name"));
 selectedWave = (waveGen.get(ScrollableList.class, "Wave_Selection").getItem(n).get("name")).toString(); 
}
/*
* Handles what control elements should be on or off. Repositions some elements as appropriate.
*/
void manageCanvas() {
  if (selectedChip == chip1){
    //EEPROM1.show();
    image(M27C512,0,0);
  }
  if (selectedChip == chip2){
    //EEPROM2.show();
    image(M2732A,0,0);
  }
  if (selectedChip != ""){
    defaults.show();
    programSelection.show();
    programSelection.setPosition(75,height-200);
    ChipSelect.setPosition(0-150,height-200);
    if(selectedProgram == logicFunctionTag) logicFunction.show();
    if(selectedProgram == waveGenTag) waveGen.show();
    logicFunction.setPosition(300,height-200);
    waveGen.setPosition(300,height-200);
  }
  if (selectedChip == ""){
    openingScreen.show();
    ChipSelect.setPosition(0+320,height/2-50);
  }
  membankSelectText2.setText(membankSelection);
  outpinText2.setText(outpinSelection);
}
/*
*Removes all GUI control elements from the canvas. Makes manageCanvas() job easier.
*/
void cleanCanvas() {
  programSelection.hide();
  EEPROM1.hide();
  EEPROM2.hide();
  defaults.hide();
  logicFunction.hide();
  waveGen.hide();
  openingScreen.hide();
}
/*
*Called then the button "Synthesis Hex" is pushed. Hook for the rest of the prgm.
*/
void SYNTHESIZE_HEX(int a){
 println("Synthesizing Intel Hex..."); 
 currentIncrement = 0;
 if(firstRun){//Because buttons are pressed at the start of a prgm run? This stops that bug.
   firstRun=!firstRun;
   return;
 }
 flashing = true;
 beginSynthesis = true; //This is to break the synthesis method out from the button return method, b/c the button method has built in error handling that obfuscates problems with Hex Generation.
}

/*
*
*/
void guiGeneratesHex(){
 TableRow newRow = WaveformSelection.addRow();
 //newRow.setString("Memory Bank", membankSelection);
 //newRow.setString("Pin", outpinSelection);
 //newRow.setString("Logic", logicString);
 newRow.setString("Memory Bank", membankSelection);
 newRow.setString("Pin", outpinSelection);
 newRow.setString("Logic", logicString);
 println(logicString);
 BurnIntelHex(WaveformSelection);   
 beginSynthesis = false;

}
/*
*Manages the background and changes it's color when necassary. Rarely needed though.
*/
void manageBackground(){
  background(currentColor);
  currentIncrement = currentIncrement +  (1- currentIncrement) * flashRate;
  if(flashing) currentColor = lerpColor(defaultColor, flashColor, currentIncrement);
  else{ currentColor = lerpColor(flashColor, defaultColor, currentIncrement);}
 
 if(currentColor==flashColor){
   flashing = false;
   currentIncrement=0;
   //println("GotIt!");
 }
 //println(flashing);

}

  






//==================================================================================================
//============ Section 2: Table Translation and Grouping============================================
//==================================================================================================
// Table maniuplation methods for sorting and otherwise manipulating truth tables and input selections
// to make iterating over inputs and generating logic possible.

/*
* Takes table with each operation enumerated by memory bank, pin, and logic. Outputs
* a table with all pins used in a single memory bank as one entry in a table, with all pins
* taking up a single entry, just coded together by Strings. This gets around Processing's lack of arrays or
* sorting ability. 
*/

Table tableGrouper(Table waveforms) {
  Table groupedWaves = new Table();
  groupedWaves.addColumn("Memory Bank", Table.STRING);
  groupedWaves.addColumn("Pin", Table.STRING);
  groupedWaves.addColumn("Logic", Table.STRING);
  //groupedWaves: MemBank, pin1_pin2_pin3....pinN, Logic1_....LogicN;
  for ( TableRow row : waveforms.rows()) {
    String bank = row.getString("Memory Bank");
    String newPin = "" + row.getString("Pin");
    String newLogic = "" + row.getString("Logic");
    String oldPins, oldLogics;
    TableRow bankRow;
    try {
      bankRow = groupedWaves.findRow(bank, "Memory Bank");
      oldPins = bankRow.getString("Pin");
      oldLogics = bankRow.getString("Logic");
    }
    catch(Exception e) {
      bankRow = groupedWaves.addRow();
      oldPins = "";
      oldLogics = "";
    }
    bankRow.setString("Memory Bank", bank);
    bankRow.setString("Pin", oldPins + newPin + "_");
    bankRow.setString("Logic", oldLogics + newLogic + "_");
  }
  return groupedWaves;
}

/*
* Takes a table of delimited Strings of the form a_b_c...n_ and turns it into a table of
* t1:
*  a
*  b
*  .
*  n
* This re-processes the strings outputed by tableGrouper into something more iterable for the truthTableGenerator
*/
Table StringToTable(String delmintedString, Table table, int column) {
  if (delmintedString.length() <= 1) return table;
  int s1 = int(delmintedString.substring(0, delmintedString.indexOf("_")));
  String sRemain = delmintedString.substring(delmintedString.indexOf("_")+1);
  TableRow newEntry = table.addRow();
  newEntry.setInt(column, s1);
  table = StringToTable(sRemain, table, column);
  return table;
}

/*
*Takes two INT single column tables t1 and t2 and pairs them up, so that 
 * t3:  t1: t2:
 * 1,2   1   2
 * 3,b   3   b
 * 3,1   3   1 
 * Tables must have same number of rows. Uses t1 rowLength to determine final output size.
 */
Table pairTwoIntTables(Table t1, Table t2) {
  Table t3 = new Table();
  t3.addColumn();
  t3.addColumn();
  for ( int i=0; i<t1.getRowCount(); i++) {
    TableRow row = t3.addRow();
    row.setInt(0, t1.getRow(i).getInt(0));
    row.setInt(1, t2.getRow(i).getInt(0));
  }
  return t3;
}

void printIntTable(Table tab) {
  for ( TableRow row : tab.rows()) {
    for (int i=0; i<tab.getColumnCount(); i++) {
      print(row.getInt(i)+ "_");
    }
    println("");
  }
}
void printWaveform(Table waveform) {
  try {
    for (TableRow row : waveform.rows()) {
      println(row.getString("Memory Bank") +"|" + row.getString("Pin") +"|" + row.getString("Logic") );
    }
  }
  catch(Exception e) {
    for (TableRow row : waveform.rows()) {
      println(row.getString("Memory Bank") +"|" + row.getInt("Pin") +"|" + row.getInt("Logic") );
    }
  }
}

//==================================================================================================
//============ Section 3: Intel Hex Generation =====================================================
//==================================================================================================
/*
*Takes the WaveformSelection Tables, Generates inputs, Assembles Truth Tables,
*    Then writes it all to a Hex File.    
*/
void BurnIntelHex(Table waveformSelection){
  Table recordTable;
  Table truthTable;
   PrintWaveformSelection();
   Table inputs = OscillatorGenerator();
   try {
     truthTable = truthtableGenerator(waveformSelection,inputs);
     println("Truth Table Generated! Outputs below:");
     printBinaryTruthTable(truthTable);
     recordTable = createIHex(truthTable);
     writeHexTable(recordTable);
     println("SYNTHESIS COMPLETE");
   } catch (Exception e) {
     //e.printStackTrace();
     delay(500);
     println("Truth Table Generation FAILED. Please try again.");
   }
   //exit();  
}
/*
*Iterates through a table of hex strings and writes it to a file.
*/
void writeHexTable(Table table){
  
  PrintWriter output;
  output = createWriter("data/" +FILENAME);
  for( TableRow row: table.rows() ){
    output.println(row.getString(0));
    println(row.getString(0));
  }
  output.flush();
  output.close();
  println("Wrote to the following hex file: "+ FILENAME);
}
void PrintWaveformSelection(){
  println("  Memory Bank:\t  Pin:\t Logic Function:");
 for (TableRow row: WaveformSelection.rows()){
    println("  " + row.getString("Memory Bank")+ "\t\t" + row.getString("Pin") + "\t\t" + row.getString("Logic") );
 }
}

/*
* Translates truth table of form (addr, output pins) into a string of Intel Hex.
*/
Table createIHex(Table truthTable) {
  Boolean firstAddr = true;
  String recordAddr = "";
  String currAddr = "";
  String lastAddr = "";
  String recordData = "";
  String hexByte = "";
  int byteCount = 0;
  String runningSum = "0";
  Table recordTable = new Table();
  final int byteLimit = 16;  //16 is the cultural Standard max byteCount per record in IntelHex;
  
  for (TableRow row : truthTable.rows()) {
    hexByte = hex(unbinary(row.getString(1)), 2);
    currAddr = hex(unbinary(row.getString(0)), 3);
    if(firstAddr){
      recordAddr = currAddr;       
      recordData = hexByte;
      runningSum = hexByte;
      
      firstAddr = false;
      byteCount++;
    }else{   
      if( isSequential(lastAddr,currAddr) & byteCount < byteLimit){ //Test to determine whether to start a new record (new line), or continue concantinating data.
       recordData = recordData + hexByte;
       byteCount++;
       runningSum= hex( unhex(runningSum) + unhex(hexByte)); //Running sum on the data for the checksum.
       
      }else{//Need to start a new record!
        TableRow newRow = recordTable.addRow();
        newRow.setString(0, processRecord(recordAddr, recordData, byteCount, runningSum));
        
        recordAddr = currAddr;       
        recordData = hexByte;
        runningSum = hexByte;        
        byteCount = 1;
      }
      
    }
    lastAddr = currAddr;
  }//end for
  TableRow newRow = recordTable.addRow();//Add the record skipped by the for loop of iHex encoding
  newRow.setString(0, processRecord(recordAddr, recordData, byteCount, runningSum));
  TableRow eofRow = recordTable.addRow();
  eofRow.setString(0, ":"+"00"+"0000"+"01"+"FF"); //EOF Record.
  return recordTable;
}
/*
*Finializes a single line of Intel Hex, for createIHex(). Trivia; a single line of iHex is called a record.
*/
String processRecord(String recordAddr, String recordData, int byteCount, String dataSum){
  dataSum = hex( unhex(dataSum) + byteCount, 2);
  String checksum = hex( unhex("FF") - unhex(dataSum)+1   ,2);
  String record = ":"+hex(byteCount,2)+hex(unhex(recordAddr),4)+"00"+ recordData + checksum;
  return record;
}

/*
*Prints all the output values stored in a table. Useful for debugging.
*/
void printOutputs(Table truthTable){
    for (TableRow row : truthTable.rows()) {
    println("no_cast: " +row.getString(1));
    println("int: " +unbinary(row.getString(1)));
    println("hex: " + hex(unbinary(row.getString(1)), 2)) ;
    }
}
/*
*Prints all the address values stored in a table. Useful for debugging.
*/
void printAddresses(Table truthTable){
    for (TableRow row : truthTable.rows()) {
    println("no_cast: " +row.getString(0));
    println("int: " +unbinary(row.getString(0)));
    println("hex: " + hex(unbinary(row.getString(0)), 2)) ;
    }
}
/*
*Returns True if two hex numbers are sequential to one and other
 */
Boolean isSequential(String hex1, String hex2) {
  int i1, i2;
  i1 = unhex(hex1);
  i2 = unhex(hex2);
  return i2==(i1+1);
}


//==================================================================================================
//============ Section 4: Logic and Truth Tables =====================================================
//==================================================================================================
//Everything responsible for getting a truth table ready.


/*
*Takes in an input of oscillators, and an input of control strings (logic function, waveform, sin cos etc.)
*and outputs a Processing table of the form: (Inputs, Outputs)
*/
Table truthtableGenerator(Table waveformSelection, Table inputs){
  println("Function Outputs:");
  println("(Membank_InputBin_OutputBin_OutputInt)");
  Table truthTable = new Table();
  truthTable.addColumn("Address", Table.STRING);
  truthTable.addColumn("Outputs", Table.STRING);
  String selAddr = membankSelection; //"Memory Bank"
  String pinString = outpinSelection;//"Pin"
  //String logicString = logicString;//"Logic"
  //Table pT = new Table(); Table lT = new Table();
  //pT.addColumn();lT.addColumn();
  //StringToTable(pinString,pT,0);
  //StringToTable(logicString,lT,0);
  //Table pinAndLogic = pairTwoIntTables(pT,lT);
  //int waveform= -1;
  println("Generating Truth Table!!!!");
  
  String logicAnswer = "";
  String[] waveAnswer = {};
  if(selectedProgram == logicFunctionTag) logicAnswer = generateFullLogic(logicString);
  if(selectedProgram == waveGenTag) waveAnswer = generateFullWaveform(selectedWave).split(",");
  int memPosition = 0;
  for( TableRow oscRow: inputs.rows()){ //Iterates through every input.
    String outputs = "0000"+"0000"; //Default 8 output pins.
    String input = oscRow.getString(0);
    char one = '1';
    if(selectedProgram == logicFunctionTag){
      for( int pinIndex=0; pinIndex<pinString.length(); pinIndex++){
          if(pinString.charAt(pinIndex) == one) outputs = replaceCharAt(pinIndex, logicAnswer.charAt(memPosition) , outputs );
      }}
    if(selectedProgram == waveGenTag){
      outputs = waveAnswer[memPosition+1];
      memPosition = memPosition-1;
      }     
    memPosition = memPosition+2;      
    println(selAddr+"_"+input+"_"+outputs+"_"+str(unbinary(outputs)));
    TableRow singleLine = truthTable.addRow(); 
    singleLine.setString(0,selAddr+input); //Sets truth table address
    singleLine.setString(1,outputs);   //Sets truth table output.
  }
return truthTable;
}

/*
* Returns big string of all boolean answers to an arbitrary logic function encapsulated by str logicFunction.
* Works by instantiating a Javascript engine and then executing arbitrary code. This is also pretty novel to Processing. Only ever saw it done in Java.
*/
String generateFullLogic(String logicFunction){
   if(logicFunction.indexOf(logicFileExtension) != -1){
     String default_filename = FILENAME;
     try{
       println("logic file detected...");
       String lines[] = loadStrings(logicFunction);
       String temp = "";
       for (int i=0; i<lines.length; i++){
        int comment = lines[i].indexOf("//");
        if( comment != -1){
          temp+= lines[i].split("//")[0];
        }else{
        temp+= lines[i]; 
         }
       }
       
       FILENAME = logicFunction.split(logicFileExtension)[0];
       FILENAME = FILENAME + ".hex";
       
       logicFunction = temp;
       println("File's Function:");
       println(logicFunction);
     }
     catch (Exception e){
       FILENAME = default_filename; 
      println("Error: Bad Logic file given.");
     }
 }
  
  
  
  
  
  
    String varInit =    "var A0 = 0; ";
    varInit = varInit + "var A1 = 0; ";
    varInit = varInit + "var A2 = 0; ";
    varInit = varInit + "var A3 = 0; ";
    varInit = varInit + "var A4 = 0; ";
    varInit = varInit + "var A5 = 0; ";
    varInit = varInit + "var A6 = 0; ";
    varInit = varInit + "var A7 = 0; ";
    String scriptInit = "var k = " + str(int(pow(2,NUM_OSC))) + ";";
    scriptInit+= "print(\"\\nParsed Logic Function: "  + logicFunction + "\");";
    String forLoop  = "";
    forLoop += "var answer = \"\"; ";
    forLoop += "for(i=0; i<k; i++){";
    forLoop += "   var binStr = (i+" + str(int(pow(2,NUM_OSC)))+ ").toString(2).substring(1); "; //Substring and adding 2^8 gives zero padding. Neat hack
    forLoop += "   A0 = binStr[0];";
    forLoop += "   A1 = binStr[1];";
    forLoop += "   A2 = binStr[2];";
    forLoop += "   A3 = binStr[3];";
    forLoop += "   A4 = binStr[4];";
    forLoop += "   A5 = binStr[5];";
    forLoop += "   A6 = binStr[6];";
    forLoop += "   A7 = binStr[7];";
    forLoop += "   var stagedAnswer = " + logicFunction + ";";
    forLoop += "   answer += stagedAnswer + \",\";";
    //forLoop += "   print(binStr+\"_\"+stagedAnswer);";
    forLoop += "}";
    ScriptEngineManager mgr = new ScriptEngineManager();
    ScriptEngine engine = mgr.getEngineByName("javascript");
    try {
      String initCode = "load(\"nashorn:mozilla_compat.js\"); importPackage(java.util);"; // The load statement makes the script engine compatible with the importPackage call.
      engine.eval(initCode);
      engine.eval(varInit+scriptInit);
      engine.eval(forLoop);
      String answer = engine.get("answer").toString();

      return answer;
      //x =a;  
    }
    catch (Exception e) {
      println("ERROR; Perhaps bad Logic Function?");
      e.printStackTrace();
    } 
    
    return "Logic Failed. Please Try again.";
}
 
/*
*Given a logic function and string of 0,1 inputs, evaluates a single answer to the logic function. Useful for debugging, not used in final truth table generation.
*/
boolean evalLogicString(String logicFunction, int a, int b, int c, int d, int e2, int f, int g, int h){
 String varCode = "var a = " +str(a) + "; ";
 varCode = varCode +  "var b = " +str(b) + "; ";
 varCode = varCode +  "var c = " +str(c) + "; ";
 varCode = varCode +  "var d = " +str(d) + "; ";
 varCode = varCode +  "var e = " +str(e2) + "; ";
 varCode = varCode +  "var f = " +str(f) + "; ";
 varCode = varCode +  "var g = " +str(g) + "; ";
 varCode = varCode +  "var h = " +str(h) + "; ";
ScriptEngineManager mgr = new ScriptEngineManager();
ScriptEngine engine = mgr.getEngineByName("javascript");
try {
  String initCode = "load(\"nashorn:mozilla_compat.js\"); importPackage(java.util);";
  engine.eval(initCode);
  engine.eval(varCode);
  engine.eval("var answer = " + logicFunction + ";");
  String answer = engine.get("answer").toString();
  boolean boolAnswer = !answer.equals("0");
  return boolAnswer;
}
catch (Exception e) {
  println("ERROR; Perhaps bad Logic Function?");
  e.printStackTrace();
}   
 return false; 
}

/*
* Selects between waveform functions.
*/
String generateFullWaveform(String selectedWave){
  println("Selected Wave: " + selectedWave);
  switch(selectedWave){
    case sinTag:
      return genSin();
    case cosTag:
      return genCos();
    case squareTag:
      return genSquare();
    case sawTag:
       return genSaw();
    default:
      println("Error, somehow waveform was not selected properly. Please try again or patch"); 
    }
    return "";
}


/*
*Creates sin wave from incrementing addresses. Output in form ",0000000,00000110,11110010,00101"
*/
String genSin(){
  String outputs = "0000"+"0000";
  Table inputs = OscillatorGenerator();
  float addr;
  float phi = 0; //Somewhere between 0 and 1
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = 2*3.14159;
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1; //Vertical Shift so no negative binary nonesense.
  outputs = "";
  for( TableRow state : inputs.rows() ){
    addr = unbinary(state.getString(0));
    float operation = sin(((addr/maxAddr+phi)%1)*period);
    int answer = int((operation+scaleB)*scaleM/2);
    outputs = outputs + "," + binary(answer,outSize);
  }
  //println(outputs);
  return outputs;
}
/*
*Generates Cos wave Output in form ",0000000,00000110,11110010,00101"
*/
String genCos(){ 
    String outputs = "0000"+"0000";
  Table inputs = OscillatorGenerator();
  float addr;
  float phi = 0;//Somewhere between 0 and 1
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = 2*3.14159;
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1; //Vertical Shift so no negative binary nonesense.
  outputs = "";
  for( TableRow state : inputs.rows() ){
    addr = unbinary(state.getString(0));
    float operation = cos(((addr/maxAddr+phi)%1)*period);
    int answer = int((operation+scaleB)*scaleM/2);
    outputs = outputs + "," + binary(answer,outSize);
  }
  //println(outputs);
  return outputs;
}
/*
*Generates square wave  Output in form ",0000000,00000110,11110010,00101"
*/
String genSquare(){
   String outputs = "0000"+"0000";
  Table inputs = OscillatorGenerator();
  float addr;
  float phi = 0;//Somewhere between 0 and 1
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = .5; //Period must be less than 1. Period of 1 means it takes a full 8 input roll over time. 
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1; //Vertical Shift so no negative binary nonesense.
  outputs = "";
  for( TableRow state : inputs.rows() ){
    addr = unbinary(state.getString(0));
    int answer = int( floor(((addr/maxAddr+phi)%1)/period*2)%2  );
    outputs = outputs + "," + binary(answer,1) + binary(answer,1)+ binary(answer,1)+ binary(answer,1)+ binary(answer,1)+ binary(answer,1)+ binary(answer,1)+ binary(answer,1);
  }
  //println(outputs);
  return outputs;
}  


String genSaw(){
     String outputs = "0000"+"0000";
  Table inputs = OscillatorGenerator();
  float addr;
  float phi = 0;//Somewhere between 0 and 1
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = 1; //Period must be less than 1. Period of 1 means it takes a full 8 input roll over time. 
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1; //Vertical Shift so no negative binary nonesense.
  outputs = "";
  for( TableRow state : inputs.rows() ){
    addr = unbinary(state.getString(0));
    int stage1 = int( ((((addr/maxAddr+phi)%1)/period))*maxAddr);
    int answer = stage1;
    if(stage1>1) answer = 1-stage1;
    //int answer = int( floor((addr/maxAddr+phi)/period*2)%2  );
    outputs = outputs + "," + binary(answer,outSize);
  }
  //println(outputs);
  return outputs;
}  


String genPWM(){
  String outputs = "";
  
  //Just a thought...
  return outputs;
}  




String waveformSIN(String str){
  Table inputs = OscillatorGenerator();
  String outputs = "0000"+"0000";
  float addr = unbinary(str);
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = 2*3.14159;
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1;
  outputs = "";
  for( TableRow state : inputs.rows() ){
    addr = unbinary(state.getString(0));
    float operation = sin(addr/maxAddr*period);
    int answer = int((operation+scaleB)*scaleM/2);
    outputs = outputs + "," + binary(answer,outSize);
  }
  println(outputs);
  return outputs;
}

/*
*Creates cos wave from incrementing addresses.
*/
String waveformCOS(String str){
  String outputs = "0000"+"0000";
  float addr = unbinary(str);
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = 2*3.14159;
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1;
  float operation = cos(addr/maxAddr*period);
  int answer = int((operation+scaleB)*scaleM/2);
  outputs = binary(answer,outSize);
  //println(outputs+"_"+answer);
  return outputs;
}


/* TO MODIFY: Roll your own waveform function. Given a sequence of 0-255 binary number, what is the output?
*Creates ??? wave from incrementing addresses.
*/
/*To Modify: Uncomment and change the operation function below.
String waveform???(String str){
  String outputs = "0000"+"0000";
  float addr = unbinary(str);
  float maxAddr = unbinary("1111"+"1111"); //Assumes 8 bit address space;
  float period = 2*3.14159;
  float scaleM = unbinary("1111"+"1111");//Vertical stretch to fit the address space;
  float scaleB = 1;
  float operation = cos(addr/maxAddr*period);//To Modify: Add your own waveform function here. Must have max/min from 1 to -1 and have a period of 2PI
  int answer = int((operation+scaleB)*scaleM/2);
  outputs = binary(answer,outSize);
  //println(outputs+"_"+answer);
  return outputs;
}
*/


/*
*
*
*    OLD LOGIC CODE. DOESN'T DO MUCH, BUT COULD BE USEFULL IF CHANGING LOGIC PARADIGM INTO A MULTIPLE FUNCTION PER ENTRY KIND OF DEAL.
*
*
*/

/*
* To modify: Performs ???? Logic
*/
int logicCUST_1(String str){
  int a,b,c,d,e,f,g,h, answer;
  int normal = int('0');
  //println("Inputs_" + str);
  a = int(str.charAt(0))-normal; //Converts String of Oscillator inputs into integers for Processing Logic.
  b = int(str.charAt(1))-normal;
  c = int(str.charAt(2))-normal;
  d = int(str.charAt(3))-normal;
  e = int(str.charAt(4))-normal;
  f = int(str.charAt(5))-normal;
  g = int(str.charAt(6))-normal;
  h = int(str.charAt(7))-normal;
  //println(a+"_?!"+ b+c+d+e+f+g+h);
  answer = a & b & c & d & e & f & g & h ; //To Modify: If spinning your own logic function, change these symbols here.
  return answer;
}

/*
* To modify: Performs ???? Logic
*/
int logicCUST_2(String str){
  int a,b,c,d,e,f,g,h, answer;
  int normal = int('0');
  //println("Inputs_" + str);
  a = int(str.charAt(0))-normal; //Converts String of Oscillator inputs into integers for Processing Logic.
  b = int(str.charAt(1))-normal;
  c = int(str.charAt(2))-normal;
  d = int(str.charAt(3))-normal;
  e = int(str.charAt(4))-normal;
  f = int(str.charAt(5))-normal;
  g = int(str.charAt(6))-normal;
  h = int(str.charAt(7))-normal;
  //println(a+"_?!"+ b+c+d+e+f+g+h);
  answer = a & b & c & d & e & f & g & h ; //To Modify: If spinning your own logic function, change these symbols here.
  return answer;
}

/*
*Simulates a bank of 8 oscillators and creates a table of all possible states.
*/
Table OscillatorGenerator(){
  Table oscillators = new Table();
  int k = int(pow(2,NUM_OSC));
  for( int i=0; i<k; i++){
    TableRow set = oscillators.addRow();
    set.setString(0,(binary(i,NUM_OSC)));
  }
  return oscillators;
}

void printTruthTable(Table truthTable){
    for (TableRow row : truthTable.rows()) {
    println(hex(unbinary(row.getString(0)), 2)+ "_"+ hex(unbinary(row.getString(1)), 2)) ;
    }
}
void printBinaryTruthTable(Table truthTable){
    for (TableRow row : truthTable.rows()) {
    println((row.getString(0))+ "_"+ row.getString(1)) ;
    }
}

/*
*Processes a CSV and returns the Table of our addresses and outputs. Allows for arbitrary truth table inputs without this program!!!
 */
Table CSVprocess() {
  Table table;
  Table truthTable = new Table();
  int rowNum = 0;
  table = loadTable(TruthTableName, "header");
  
  for (TableRow row : table.rows()) {
    String addr ="";
    String out = "";
    for (int i=1; i<=addrSize; i++) {  //captures each digit in input address and concantenates them into a single String
      addr = addr +row.getString(addrName+i);
    }
    for (int i=1; i<=outSize; i++) {
      out = out + row.getString(outName+i);  //Concantenates the outputs into a single String
    }
    truthTable.addRow();
    truthTable.setString(rowNum, 0, addr);
    truthTable.setString(rowNum, 1, out);//Adds the parsed CSV data to our return Table.
    rowNum++;
  }
  return truthTable;
}

/*
* Given an index, a character, and a String, returns a String with that character replaced in the string at said index.
*/
String replaceCharAt(int i, char c, String repl){
 char primeRepl[] = new char[repl.length()];
 primeRepl = repl.toCharArray();
 primeRepl[i] = c;
 return new String(primeRepl); 
}