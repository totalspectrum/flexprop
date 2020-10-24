/*
  Set Volts.c
  
  Set voltages at D/A 0 with P26 and at D/A 1 with P27.
  V(D/A) = daVal * 3.3 V / 256.

  Examples:
    78 * 3.3 V / 256 -> 1 V
    233 * 3.3 V / 256 -> 3 V.
    
  For more options and channels, use: 
    Learn\Simple Libraries\Convert\libdacctr   

  Additional info:  
  http://learn.parallax.com/propeller-c-simple-circuits/set-volts
*/

#include "simpletools.h"                      // Include simpletools

int main()                                    // main function
{
  dac_ctr(26, 0, 194);                        // 2.5 V to D/A0
  dac_ctr(27, 1, 78);                         // 1 V to D/A1
  pause(2000);                                // Pause 2 seconds
  dac_ctr(26, 0, 78);                         // 1 V to D/A0
  dac_ctr(27, 1, 194);                        // 1.5 V to D/A1
  pause(2000);                                // Pause 2 seconds
  dac_ctr_stop();                             // Stop D/A cog
}
