/*
  Sense Light.side

  Display light sensor levels.
  
  http://learn.parallax.com/propeller-c-simple-circuits/sense-light
*/

#include "simpletools.h"                      // Include simpletools

int main()                                    // main function
{
  while(1)                                    // Endless loop
  {
    high(15);                                 // Set P5 high
    pause(1);                                 // Wait for circuit to charge
    int t = rc_time(15, 1);                   // Measure decay time on P5
    print("t = %d\n", t);                     // Display decay time
    pause(100);                               // Wait 1/10th of a second
  }
}
