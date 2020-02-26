/*
  EEPROM Program Modes.c

  Use EEPROM to advance modes with each press/release of the reset button.
  Also advances with each power-off, power-on cycle.  
  
  IMPORTANT: Make sure to use SimpleIDE's Load EEPROM & Run button.  The 
  program has to be in EEPROM first.  After that, you can optionally use
  the Run with Terminal button to view the print output.   
  
  http://learn.parallax.com/propeller-c-tutorials
*/

#include "simpletools.h"                      // Include simpletools header    .

int main(void)                                // main function code starts here
{
  int addr = 32768;                           // Lowest user EEPROM address
  char mode = ee_get_byte(addr);              // Value at address 32768 -> mode
  mode += 1;                                  // Add one
  mode %= 3;                                  // Modulus (remainder of mode / 3)
  ee_put_byte(mode, addr);                    // New mode -> EEPROM addr 32768

  print("Startup mode = %d \n", mode);        // Display mode

  switch(mode)                                // Decide how the program behaves
  {
    case 0:                                   // If mode == 0, P26 light on
      high(26);
      break;
    case 1:                                   // If mode == 1, P27 light on
      high(27);
      break;
    case 2:
      high(26);                               // If mode == 2, both lights on
      high(27); 
      break;
  }

  while(1);                                   // Keep light(s) on
}
