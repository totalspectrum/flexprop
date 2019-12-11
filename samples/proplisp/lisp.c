//
// lisp interpreter REPL (read-evaluate-print loop)
//
#include <stdio.h>
#include <stdlib.h>
#include "lisplib.h"

#ifdef __propeller__

#include <propeller.h>
#ifdef __P2__
#define P2_TARGET_MHZ 160
#include "sys/p2es_clock.h"
#define ARENA_SIZE 32768
#else
#define ARENA_SIZE 4096
#endif

#elif defined(__zpu__)

#define ARENA_SIZE 4096

#else

#define ARENA_SIZE 65536
#define MAX_SCRIPT_SIZE 100000

#endif

// make these whatever you need to switch terminal to
// raw or cooked mode

#ifdef __linux__
#include <termios.h>
#include <unistd.h>
struct termios origt, rawt;

static void setraw() {
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stdin, NULL, _IONBF, 0);

    tcgetattr(fileno(stdin), &origt);
    rawt = origt;
    cfmakeraw(&rawt);
    tcsetattr(fileno(stdin), TCSAFLUSH, &rawt);
}
static void setcooked() {
    tcsetattr(fileno(stdin), TCSAFLUSH, &origt);
}
#else
// make these whatever you need to switch terminal to
// raw or cooked mode
static void setraw() {
}
static void setcooked() {
}
#endif

#if defined(__propeller__)

#ifdef __GNUC__
#include "PropSerial/FullDuplexSerial.h"
FullDuplexSerial fds;
#define FDS_START(a, b, c, d) FullDuplexSerial_start(&fds, a, b, c, d)
#define FDS_TX(c) FullDuplexSerial_tx(&fds, c)
#define FDS_RX() FullDuplexSerial_rxcheck(&fds)
#endif
#ifdef __FLEXC__
#ifdef __P2__
struct __using("PropSerial/SmartSerial.spin2") fds;
#else
struct __using("PropSerial/FullDuplexSerial.spin") fds;
#endif
#define FDS_START(a, b, c, d) fds.start(a, b, c, d)
#define FDS_TX(c) fds.tx(c)
#define FDS_RX() fds.rxcheck()
#endif

int peekchar() {
    return FDS_RX();
}
int inchar() {
    int c;
    do {
        c = peekchar();
    } while (c < 0);
    return c;
}
void outchar(int c) {    
    if (c == '\n') {
        FDS_TX(13);
    }
    FDS_TX(c);
}
#elif defined(__zpu__)
int peekchar() {
    return -1;
}
int inchar() {
    return getchar();
}
void outchar(int c) {
    if (c == '\n') {
        putchar('\r');
    }
    putchar(c);
}
#else
int peekchar() {
    return -1;
}
int inchar() {
    return getchar();
}
void outchar(int c) {
    if (c == '\n') {
        putchar('\r');
    }
    putchar(c);
}
#endif

#ifdef MAX_SCRIPT_SIZE
char script[MAX_SCRIPT_SIZE];

void
runscript(const char *filename)
{
    FILE *f = fopen(filename, "r");
    int r;
    if (!f) {
        perror(filename);
        return;
    }
    r=fread(script, 1, MAX_SCRIPT_SIZE, f);
    fclose(f);
    if (r <= 0) {
        fprintf(stderr, "File read error on %s\n", filename);
        return;
    }
    script[r] = 0;
    Lisp_Run(script, 1);
}
#endif

#ifdef __propeller__
#include <unistd.h>

static intptr_t getcnt_fn()
{
    return CNT;
}

// wait for ms millisconds
static intptr_t waitms_fn(intptr_t ms)
{
#ifdef __FLEXC__
    pausems(ms);
#else    
    usleep(ms * 1000);
#endif    
    return ms;
}

#ifdef __P2__
static intptr_t pinhi_fn(intptr_t pin)
{
    __asm {
        drvh pin
    }
    return 1;
}
static intptr_t pinlo_fn(intptr_t pin)
{
    __asm {
        drvl pin
    }
    return 0;
}
static intptr_t pintoggle_fn(intptr_t pin)
{
    __asm {
        drvnot pin
    }
    return 0;
}
static intptr_t pinout_fn(intptr_t pin, intptr_t onoff)
{
    if (onoff) {
        pinhi_fn(pin);
    } else {
        pinlo_fn(pin);
    }
    return onoff;
}
static intptr_t pinin_fn(intptr_t pin)
{
    int rxbyte = -1;
    __asm {
        testp pin wc
      if_c rdpin rxbyte, pin
      if_c shr rxbyte, #24
    }
    return rxbyte;
}

#else
static intptr_t pinout_fn(intptr_t pin, intptr_t onoff)
{
    unsigned mask = 1<<pin;
    DIRA |= mask;
    if (onoff) {
        OUTA |= mask;
    } else {
        OUTA &= ~mask;
    }
    return onoff;
}
static intptr_t pintoggle_fn(intptr_t pin)
{
    unsigned mask = 1<<pin;
    DIRA |= mask;
    OUTA ^= mask;
    return 0;
}
static intptr_t pinhi_fn(intptr_t pin) { return pinout_fn(pin, 1); }
static intptr_t pinlo_fn(intptr_t pin) { return pinout_fn(pin, 0); }

static intptr_t pinin_fn(intptr_t pin)
{
    unsigned mask=1<<pin;
    DIRA &= ~mask;
    return (INA & mask) ? 1 : 0;
}
#endif

#else
// compute a function of two variables
// used for testing scripts
static intptr_t testfunc(intptr_t x, intptr_t y, intptr_t a, intptr_t b)
{
    (void)a;
    (void)b;
    return x*x + y*y;
}
#endif

LispCFunction defs[] = {
#ifdef __propeller__
    { "getcnt",    "n",   (GenericFunc)getcnt_fn },
    { "pinout",    "nnn", (GenericFunc)pinout_fn },
    { "pinlo",     "nn",  (GenericFunc)pinlo_fn },
    { "pinhi",     "nn",  (GenericFunc)pinhi_fn },
    { "pintoggle", "nn",  (GenericFunc)pintoggle_fn },
    { "pinin",     "nn",  (GenericFunc)pinin_fn },
    { "waitms",    "nn",  (GenericFunc)waitms_fn },
#else
    { "dsqr",      "nnn", (GenericFunc)testfunc },
#endif
    { NULL, NULL, 0 }
};

//
// an attempt to provide a "nice" read-evaluate-print loop
// we count ( and prompt the user based on those,
// only evaluating when the expression is done
//
#define SIZE 256

void prompt(int n) {
    if (n < 0) {
        outchar('?');
    }
    while (n > 0) {
        outchar('>');
        --n;
    }
    outchar(' ');
}

void outstr(const char *s) {
    int c;
    while (0 != (c = *s++)) outchar(c);
}

char *
getOneLine()
{
    static char buf[SIZE];
    int strcount = 0;
    int instring = 0;
    int c, i;
    int parencount = 0;
    int firstprompt = 1;
    
    prompt(firstprompt);
    for(;;) {
        buf[strcount] = 0;
        c = inchar();
        switch (c) {
        case 12: // ^L means refresh
            outchar('\n');
            outstr(buf);
            break;
        case 3:  // ^C means terminate
            outchar('\n');
            return NULL;
        case 8: // ^H is backspace
        case 127:
            if (strcount > 0) {
                c = buf[--strcount]; // the character we are about to erase
                if (c == '"') instring = !instring;
                else if (c == '(') --parencount;
                else if (c == ')') ++parencount;
                if (c == '\n') {
                    // OK, this is cute, we're going to back up a line
                    outchar('\n');
                    buf[strcount] = 0;
                    outstr(buf);
                } else {
                    c = 8;
                    outchar(c); outchar(' '); outchar(c);
                }
            }
            break;
        case '"':
            instring = !instring;
            goto output;
        case '(':
            if (!instring) parencount++;
            goto output;
        case ')':
            if (!instring) --parencount;
            goto output;
        case '\n':
        case '\r':
            c = '\n';
            outchar(c);
            buf[strcount++] = c;
            buf[strcount] = 0;
            if (parencount > 0) {
                if (firstprompt) {
                    outstr(buf);
                    firstprompt = 0;
                }
                for (i = 0; i < parencount; i++) {
                    outchar(' ');
                    buf[strcount++] = ' ';
                }
                buf[strcount] = 0;
            } else {
                return buf;
            }
            break;
        output:
        default:
            outchar(c);
            buf[strcount++] = c;
        }
    }

    return buf;
}

void
REPL()
{
    char *ptr;
    Cell *result;

    for(;;) {
        setraw();
        ptr = getOneLine();
        setcooked();
        if (!ptr) {
            break;
        }
        result = Lisp_Run(ptr, 0);
        Lisp_Print(result);
        outchar('\n');
    }
}

char arena[ARENA_SIZE];

int
main(int argc, char **argv)
{
    Cell *err;
    int i;

#ifdef __propeller__
#ifdef __P2__
    clkset(_SETFREQ, _CLOCKFREQ);
    //clkset(0x10c3f04, 160000000);
    FDS_START(63, 62, 0, 230400);
    pausems(200);
#else
    FDS_START(31, 30, 0, 115200);
#endif
    outstr("PropLisp started!\r\n");
#endif
    err = Lisp_Init(arena, sizeof(arena));
    for (i = 0; err && defs[i].name; i++) {
        err = Lisp_DefineCFunc(&defs[i]);
    }
    if (err == NULL) {
        outstr("Initialization of interpreter failed!\n");
        return 1;
    }
#ifdef SMALL
    REPL();
#else
    if (argc > 2) {
        outstr("Usage: proplisp [file]\n");
    }
    if (argv[1]) {
        runscript(argv[1]);
    } else {
        REPL();
    }
#endif
    return 0;
}
