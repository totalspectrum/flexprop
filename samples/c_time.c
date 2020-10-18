//
// simple clock program
// shows how to set the time to a specific date/time
// and then display it
//
#include <stdio.h>
#include <sys/time.h>

int main()
{
    struct timeval tv;
    struct tm tm_now;
    char dispbuf[40];
    
    // set the time to 2020-October-17, 1:30 pm
    // set up structure
    memset(&tm_now, 0, sizeof(tm_now));
    tm_now.tm_sec = 0;
    tm_now.tm_min = 30;
    tm_now.tm_hour = 13; // 1pm
    tm_now.tm_mon = 10 - 1;  // month is offset by 1
    tm_now.tm_mday = 17;
    tm_now.tm_year = 2020 - 1900;  // year is offset relative to 1900

    // convert to seconds + microseconds
    tv.tv_sec = mktime(&tm_now); // set seconds
    tv.tv_usec = 0;              // no microsecond offset

    // and set the time
    settimeofday(&tv, 0);

    // now continuously display the time
    for(;;) {
        // get current time
        gettimeofday(&tv, 0);
        // get an ASCII version of the time
        // uses the standard C library strftime function
        strftime(dispbuf, sizeof(dispbuf), "%a %b %d %H:%M:%S %Y", localtime(&tv.tv_sec));
        // print it
        printf("%s\r", dispbuf);
    }
}
