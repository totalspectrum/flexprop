/*
  EEPROM Data.c

  Write values and text to the Proepller Chip's dedicated EEPROM, and then
  read back and display.
  
  http://learn.parallax.com/propeller-c-tutorials
*/

#include "simpletools.h"                      // Include simpletools header    .

int main(void)                                // main function
{
  int addr = 32769;                           // Pick EEPROM base address. 

  ee_putInt(42, addr);                        // 42 -> EEPROM address 32769
  int eeVal = ee_getInt(addr);                // EEPROM address 32769 -> eeVal
  print("myVal = %d\n", eeVal);               // Display result

  ee_putStr("hello!\n", 8, addr + 4);         // hello!\n -> EEPROM 32773..32780
  char s[8];                                  // Character array to hold string
  ee_getStr(s, 8, addr + 4);                  // EEPROM 32773..32780 -> s[0]..s[7]
  print("s = %s", s);                         // Display s array
}

