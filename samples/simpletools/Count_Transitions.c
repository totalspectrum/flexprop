/*
  Count Transitions.c
  
  Flash P26 at 10 Hz for 10 seconds.  After 1 s, count transitions for 1 s
  and report the count.
  
  http://learn.parallax.com/propeller-c-tutorials
*/

#include "simpletools.h"                      // Include simpletools

int main()                                    // main function
{
#if 0
  int z = 0;
  int y = 0x2800_0000;

  for (int i = 0; i < 40; i++)
  {
    print("0x%08x %d \n", z, ((z&0x8000_0000) != 0) ? 1 : 0);
    z += y;
  }

  return;
#endif
  low(0);
  high(0);

  square_wave(3, 0, 1000);                      // P3, ch0, 1000 Hz.
  pause(1000);                                // Pause 1 second

#ifdef __propeller2__
  int cycles = count(4, 1000, 3);             // Count for 1 second. use pin 4 to count pin 3 rises
#else
  int cycles = count(3, 1000);                // Count for 1 second
#endif
  print("cycles = %d\n", cycles);             // Report on/off cycles

  // Negative pin clears signal and lets go of I/O pin.
  square_wave(-3, 0, 0);                     
}
