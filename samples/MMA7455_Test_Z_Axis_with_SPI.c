/*
  MMA7455 Test Z Axis with SPI.c
  
  Demonstrates using SPI communication to configure and then monitor a 
  Parallax MMA7455 3-Axis Accelerometer Module.

  http://learn.parallax.com/propeller-c-simple-protocols/spi-example
*/

#include "simpletools.h"                          // Include simpletools lib

signed char z;                                    // Z-axis value

int main()                                        // Main function
{
  high(6);                                        // CS line high (inactive)
  low(8);                                         // CLK line low
  low(6);                                         // CS -> low start SPI

  shift_out(7, 8, MSBFIRST, 7, 0b1010110);        // Write MCTL register
  shift_out(7, 8, MSBFIRST, 1, 0b0);              // Send don't-care bit
  shift_out(7, 8, MSBFIRST, 8, 0b01100101);       // Value for MCTL register

  high(6);                                        // CS -> high stop SPI

  while(1)                                        // Main loop
  {
    low(6);                                       // CS low selects chip
    shift_out(7, 8, MSBFIRST, 7, 0b0001000);      // Send read register address
    shift_out(7, 8, MSBFIRST, 1, 0b0);            // Send don't-care value

    z = shift_in(7, 8, MSBPRE, 8);                // Get value from register

    high(6);                                      // De-select chip
    print("z = %d\n", z);        		  // Display measurement
    pause(200);                                   // Wait 0.5 s before repeat
  }
}
