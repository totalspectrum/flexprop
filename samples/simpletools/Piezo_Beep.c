/*
  Piezo Beep.c

  Beep a piezo speaker connected to Propeller I/O pin P4.
  
  http://learn.parallax.com/propeller-c-simple-circuits/piezo-beep
*/

#include "simpletools.h"                      // Include simpletools                   

int main()
{
  int f = 2;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 2000/f, f);                     // pin, duration, frequency
	f += 1;
  }
  f = 20;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 100, f);                     // pin, duration, frequency
	f += 10;
  }
  f = 200;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 10, f);                     // pin, duration, frequency
	f += 100;
  }
  f = 2000;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 2, f);                     // pin, duration, frequency
	f += 1000;
  }
  f = 20000;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 1, f);                     // pin, duration, frequency
	f += 10000;
  }
  f = 200000;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 1, f);                     // pin, duration, frequency
	f += 100000;
  }
  f = 2000000;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 1, f);                     // pin, duration, frequency
	f += 1000000;
  }
  f = 20000000;
  for (int i = 0; i < 9; i++)
  {
  	freqout(0, 1, f);                     // pin, duration, frequency
	f += 10000000;
  }
}
