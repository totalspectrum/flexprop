//
// sample to read HMC5883L compass module
// connected via i2c on pins 28 and 29
//

#include "simpletools.h"
#include <math.h>
#include <stdio.h>

#ifdef __propeller2__

// to get the frequency we desire, we
// specify P2_TARGET_MHZ then include "sys/p2es_clock.h"
// e.g. to get 160_000_000, define P2_TARGET_MHZ to 160
// p2es_clock.h defines constants _SETFREQ and _CLOCKFREQ
// which we can then use to set the clock
//
// note that this is not the only way to set the clock; you can
// certainly calculate the desired clock mode based on the frequency
// and pass the resulting mode and frequency directly to clkset()
// p2es_clock.h is just a convenience header
#define P2_TARGET_MHZ 200
#include "sys/p2es_clock.h"

#ifndef _BAUD
#define _BAUD 230400
#endif

#endif

void compass_init(i2c *bus)
{
  /* set to continuous mode */
  int modeReg = 0x02;
  unsigned char contMode = 0x00;
  int n = i2c_out(bus, 0x3C >> 1, modeReg, 1, &contMode, 1);
}

void compass_read(i2c *bus, int *px, int *py, int *pz)
{
  int16_t x16, y16, z16;
  uint8_t data[6];
  int datRegTo3 = 0x03;
  i2c_in(bus, 0x3D >> 1, datRegTo3, 1, data, 6);

  x16 = (data[0] << 8) | data[1];
  z16 = (data[2] << 8) | data[3];
  y16 = (data[4] << 8) | data[5];

  *px = x16;
  *py = y16;
  *pz = z16;
}

int main()
{
#ifdef __propeller2__
  clkset(_SETFREQ, _CLOCKFREQ);
  _setbaud(_BAUD);
  printf("clockmode is $%x, clock frequency %u Hz\n", _SETFREQ, _CLOCKFREQ);
#endif

  printf("compass init: i2c on pins 28 & 29\n");
  i2c *bus = i2c_newbus(28, 29, 0);
  compass_init(bus);

  while(1)
  {
    printf("\ncompass read: ");

    int x, y, z;
    compass_read(bus, &x, &y, &z);
    printf("x=%d, y=%d, z=%d \n", x, y, z);

    float heading = atan2(x, y);
    float headingDegrees = heading * 180/3.14; 
    printf("heading = %f, \n", headingDegrees);

    pause(20);
  }
}
