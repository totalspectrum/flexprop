//
// Copyright 2016-2019 Total Spectrum Software Inc.
// MIT Licensed; see LICENSE for exact terms
//
#include <stdio.h>
#include <stdlib.h>
#include "lisplib.h"

#include <string.h>
#include <ctype.h>

#ifdef __propeller__
#include <setjmp.h>
#endif

// define this to do some brain-dead optimization on
// lambda bodies (basically just looking up variables ahead
// of time)
//#define OPTIMIZE_LAMBDA 1

#ifdef __propeller__
jmp_buf break_buf;
#endif

static Cell *doLookup(Cell *name, Cell *env, int stopOnBoundary);

#define PENDING_ALLOCS 16

/* our context */
static struct LispContext {
    Cell *globalEnv;  // the root environment for definitions
    Cell *globalTrue; // the default "true" value
    Cell *globalQuote; // the quote function

    Cell *freeList;   // list of free nodes
    Cell *base;        // base of memory
    size_t totalCells; // number of cells in memory
    size_t freeCells;  // number of free cells

    uintptr_t *stackTop;
} *lc;

// mark all cells free, pending sweep for used cells
static void MarkFree(void) {
    size_t i, n;
    Cell *ptr = lc->base;
    n = lc->totalCells;
    for (i = 0; i < n; i++) {
        SetFree(ptr);
        ptr++;
    }
}

// collect all free cells into our free list
// and clear the "used" bit on others
static void CollectFree(void) {
    size_t i, n;
    Cell *ptr = lc->base;
    Cell *freelist = 0;
    size_t numFree = 0;
    
    n = lc->totalCells;
    for (i = 0; i < n; i++) {
        if (GetUsed(ptr)) {
            SetFree(ptr);
        } else {
            SetTail(ptr, freelist);
            freelist = ptr;
            numFree++;
        }
        ptr++;
    }
    lc->freeCells = numFree;
    lc->freeList = freelist;
}

static void InitGC(void *base, size_t size) {
    lc->base = base;
    lc->totalCells = (size / sizeof(Cell)) - 1; // reserve one for free list
    lc->stackTop = (uintptr_t *)&size;  // for garbage collection
    MarkFree();
    CollectFree();
}

static void MarkUsed(Cell *ptr) {
    int typ;
    if (!ptr) return;
    if (GetUsed(ptr)) return; // already visited
    SetUsed(ptr);
    typ = GetType(ptr);
    switch (typ) {
    case CELL_REF:
    case CELL_PAIR:
    case CELL_FUNC:
        MarkUsed(GetHead(ptr));
        /* fall through */
    case CELL_STRING:
    case CELL_SYMBOL:
        MarkUsed(GetTail(ptr));
    default:
        break;
    }
}

static void markStack(uintptr_t *low, uintptr_t *high)
{
    uintptr_t arenalow, arenahigh;
    uintptr_t dest;
    
    if (low > high) {
        uintptr_t *temp = low;
        low = high;
        high = temp;
    }
    arenalow = (uintptr_t)lc->base;
    arenahigh = (uintptr_t)(lc->base + lc->totalCells);
    while (low < high) {
        dest = *low++;
        if (dest >= arenalow && dest < arenahigh) {
            MarkUsed((Cell *)dest);
        }
    }
}

static void doGC() {
    uintptr_t i;

    // mark everything as free
    MarkFree();

    // mark the ones used in our environment
    MarkUsed(lc->globalEnv);

    // now see if anything on the stack looks like
    // it might be a pointer into our arena;
    // if so, mark it used
    markStack(&i, lc->stackTop);
    CollectFree();
}

// allocate 1 cell

Cell *GCAlloc(void) {
    Cell *r;
    
    if (lc->freeCells < PENDING_ALLOCS) {
        doGC();
        if (lc->freeCells < PENDING_ALLOCS) {
            printcstr("out of memory!\n");
        }
    }
    r = lc->freeList;
    if (r) {
        lc->freeCells--;
        lc->freeList = GetTail(r);
    }
    return r;
}

Cell *AllocRawPair(int typ, uint32_t head, uint32_t tail)
{
    Cell *x = GCAlloc();
    *x = CellPair(typ, head, tail);
    return x;
}
Cell *AllocPair(int typ, Cell *head, Cell *tail)
{
    return AllocRawPair(typ, FromPtr(head), FromPtr(tail));
}

// cons two cells
Cell *Cons(Cell *head, Cell *tail)
{
    Cell *r;
    r = AllocPair(CELL_PAIR, head, tail);
    return r;
}

Cell *IsPair(Cell *expr)
{
    int typ;
    typ = GetType(expr);
    switch (typ) {
    case CELL_PAIR:
    case CELL_REF:
        return expr;
    default:
        return NULL;
    }
}

Cell *IsString(Cell *expr)
{
    int typ;
    typ = GetType(expr);
    switch (typ) {
    case CELL_SYMBOL:
    case CELL_STRING:
        return expr;
    default:
        return NULL;
    }
}

Cell *IsNumber(Cell *expr) {
    int typ = GetType(expr);
    if (typ == CELL_NUM) return expr;
    return NULL;
}

Cell *NewCFunc(Cell *name, LispCFunction *f) {
    return AllocRawPair(CELL_CFUNC, FromPtr(name), FromPtr(f));
}
#define printchar(c) outchar(c)
#define readchar() inchar()

void printcstr(const char *s) {
    int c;
    while ( (c = *s++) != 0 ) {
        printchar(c);
    }
}

Cell *CString(const char *str) {
    Cell *head;
    Cell *last;
    Cell *next;
    int c;
    
    if (!str || (0 == (c = *str)) ) {
        return NULL;
    }
    c = *str++;
    last = head = AllocRawPair(CELL_STRING, c, 0);
    while (0 != (c = *str++)) {
        next = AllocRawPair(CELL_STRING, c, 0);
        SetTail(last, next);
        last = next;
    }
    return head;
}

Cell *CSymbol(const char *str) {
    Cell *x = CString(str);
    SetType(x, CELL_SYMBOL);
    return x;
}

Cell *CNum(Num val) {
    Cell *x = GCAlloc();
    *x = CellNum(val);
    return x;
}

Cell *StringToNum(Cell *str) {
    int typ = GetType(str);
    int c;
    int32_t val = 0;
    int negate = 0;
    if (typ != CELL_STRING) {
        return NULL;
    }
    c = GetHeadVal(str);
    if (c == '-') {
        negate = 1;
        str = GetTail(str);
    }
    while (str) {
        c = GetHeadVal(str);
        if (c >= '0' && c <= '9') {
            c = c-'0';
        } else {
            break;
        }
        val = 10*val + c;
        str = GetTail(str);
    }
    if (negate) val = -val;
    return CNum(val);
}

Cell *Append(Cell *orig, Cell *newtail)
{
    Cell *ptr;
    Cell *next;
    if (!orig) {
        return newtail;
    }
    ptr = orig;
    for(;;) {
        next = GetTail(ptr);
        if (!next) break;
        ptr = next;
    }
    SetTail(ptr, newtail);
    return orig;
}

Cell *AddCharToString(Cell *str, int c)
{
    Cell *onedigit;
    onedigit = AllocRawPair(CELL_STRING, c, 0);
    return Append(str, onedigit);
}

static Cell *doNumToString(UNum x, unsigned base, int prec) {
    int digits = 0;
    Cell *result = NULL;
    Cell *onedigit;
    int c;
    
    if (prec < 0) prec = 1;
    while (x > 0 || digits < prec) {
        c = x % base;
        x = x / base;
        if (c < 10) c += '0';
        else c = (c - 10) + 'A';
        onedigit = AllocRawPair(CELL_STRING, c, 0);
        result = Append(onedigit, result);
        digits++;
    }
    return result;
}

Cell *NumToString(Cell *num) {
    Num val = GetNum(num);
    Cell *result;
    if (val < 0) {
        result = AllocRawPair(CELL_STRING, '-', 0);
        val = -val;
    } else {
        result = NULL;
    }
    return Append(result, doNumToString(val, 10, 1));
}

static void PrintSymbol(Cell *str) {
    int c;
    while (str) {
        c = GetHeadVal(str);
        printchar(c);
        str = GetTail(str);
    }
}

//
// print a cell
// always returns NULL
//

static Cell *PrintList(Cell *str) {
    while (str) {
        switch(GetType(str)) {
        case CELL_PAIR:
            Lisp_Print(GetHead(str));
            str = GetTail(str);
            if (str) {
                if (GetType(str) == CELL_PAIR) {
                    printchar(' ');
                } else {
                    printchar('.');
                }
            }
            break;
        default:
            Lisp_Print(str);
            str = NULL;
        }   
    }
    return lc->globalTrue;
}

Cell *Lisp_Print(Cell *str) {
    int typ;

//    printcstr("[");
    typ = GetType(str);
    switch (typ) {
    case CELL_NUM:
        Lisp_Print(NumToString(str));
        break;
    case CELL_STRING:
    case CELL_SYMBOL:
        PrintSymbol(str);
        break;
    case CELL_REF:
        Lisp_Print(GetHead(str));
        break;
    case CELL_CFUNC:
        PrintSymbol(GetHead(str));
        break;
    case CELL_FUNC:
        printcstr("#<lambda>");
        break;
    default:
        printchar('(');
        PrintList(str);
        printchar(')');
    }
//    printcstr("]");
    return lc->globalTrue;
}

static Cell *undefSymbol(Cell *name)
{
    printcstr("Undefined symbol: ");
    PrintSymbol(name);
    printcstr("\n");
    return NULL;
}


// quote
Cell *Quote(Cell *a)
{
    return a;
}

// head of list
Cell *Head(Cell *x)
{
    if (IsPair(x)) {
        return GetHead(x);
    }
    return NULL;
}
Cell *Tail(Cell *x)
{
    if (IsPair(x) || IsString(x)) {
        return GetTail(x);
    }
    return NULL;
}

// define a new value, or redefine an existing one
// in the current environment
// returns the value defined
static Cell *doDefine(Cell *name, Cell *val, Cell *env)
{
    Cell *holder;
    Cell *x;
    Cell *envtail;

    // look for it in the current environment
    x = doLookup(name, env, 1); // stop at environment boundaries
    if (x && GetType(x) == CELL_REF) {
        SetTail(x, val);
        return val;
    }
    x = AllocPair(CELL_REF, name, val);
    envtail = GetTail(env);

    holder = AllocPair(CELL_PAIR, x, envtail);
    SetTail(env, holder);
    return val;
}

// check for string equality
int
stringCmp(Cell *a, Cell *b)
{
    int ac, bc;

    while (a && b) {
        ac = GetHeadVal(a);
        bc = GetHeadVal(b);
        ac = ac-bc;
        if (ac != 0) return ac;
        a = GetTail(a);
        b = GetTail(b);
    }
    // at this point there are 3 cases:
    // a and b both NULL -> success
    // a is non-NULL, b is NULL -> a is longer, so return positive
    // b is non-NULL, a is NULL -> b is longer, return negative
    if (a) {
        return 1;
    }
    if (b) {
        return -1;
    }
    return 0;
}

// check to see if two cells are equal
// numbers and functions are equal if they have the same values
// strings are equal if they match character for character
// otherwise they cells must be the same
// returns globalTrue if true, NULL if false

static Cell *doMatch(Cell *a, Cell *b, Cell *trueval, Cell *falseval)
{
    int atag, btag;
    if (a == b) {
        return trueval;
    }
    atag = GetType(a);
    btag = GetType(b);
    if (atag != btag) {
        return falseval;
    }
    switch (atag) {
    case CELL_NUM:
        return GetNum(a) == GetNum(b) ? trueval : falseval;
    case CELL_STRING:
    case CELL_SYMBOL:
        return stringCmp(a, b) == 0 ? trueval : falseval;
    default:
        return falseval;
    }
}

Cell *Match(Cell *a, Cell *b)
{
    return doMatch(a, b, lc->globalTrue, NULL);
}
Cell *NoMatch(Cell *a, Cell *b)
{
    return doMatch(a, b, NULL, lc->globalTrue);
}

// find a symbol ref
static Cell *doLookup(Cell *name, Cell *env, int stopOnBoundary)
{
    Cell *holder = NULL;
    Cell *hname = NULL;

    if (GetType(name) == CELL_REF) {
        return name; // already a reference
    }
    env = Tail(env);
    while (env) {
        holder = GetHead(env);
        if (holder) {
            hname = GetHead(holder);
            if (Match(hname, name)) {
                return holder;
            }
        } else {
            if (stopOnBoundary) {
                return NULL;
            }
        }
        env = GetTail(env);
    }
    return NULL;
}

Cell *Lookup(Cell *name, Cell *env)
{
    return doLookup(name, env, 0);  // never stop at an environment boundary
}

Cell *ReadListFromString(const char **str_p);
    
Cell *ReadQuotedString(const char **str_p) {
    Cell *result = AllocPair(CELL_PAIR, 0, 0);
    int c;
    const char *str = *str_p;
    for(;;) {
        c = *str++;
        if (!c) break;
        if (c == '"') {
            // two quotes in a row stands for one quote
            if (*str == '"') {
                str++;
            } else {
                break;
            }
        }
        result = AddCharToString(result, c);
    }
    *str_p = str;
    return GetTail(result);
}

static int startoflist(int c)
{
    return (c == '(');
}

static int endoflist(int c)
{
    return (c == 0) || (c == ')');
}

Cell *ReadItemFromString(const char **str_p)
{
    Cell *result = NULL;
    int c;
    const char *str = *str_p;
    int alldigits = 1;
again:
    do {
        c = *str++;
    } while (isspace(c));
    if (c == ';') {
        // skip to end of line
        do {
            c = *str++;
        } while (c && c != '\n');
        if (c) goto again;
    }
    *str_p = str;
    // collect the next token
    if (startoflist(c)) {
        return ReadListFromString(str_p);
    }
    if (endoflist(c)) {
        *str_p = str - 1; // put back the delimiter
        return NULL;
    }
    if (c == '"') {
        return ReadQuotedString(str_p);
    }
    if (c == '\'') {
        // quoted item
        result = ReadItemFromString(str_p);
        return Cons(lc->globalQuote, Cons(result, NULL));
    }
    if (c == '-' && isdigit(*str)) {
        result = AddCharToString(result, c);
        c = *str++;
    }
    do {
        result = AddCharToString(result, c);
        alldigits = alldigits && isdigit(c);
        c = *str++;
    } while (c != 0 && !isspace(c) && !endoflist(c));

    if (!endoflist(c)) {
        // skip delimiter
        *str_p = str;
    } else {
        *str_p = str-1;
    }
    // test here for numbers, symbols, etc.
    if (alldigits) {
        return StringToNum(result);
    }
    SetType(result, CELL_SYMBOL);
    return result;
}

Cell *ReadListFromString(const char **str_p)
{
    Cell *result = NULL;
    Cell *x;
    int c;
    const char *str;

    for(;;) {
        x = ReadItemFromString(str_p);
        if (!x) {
            // is there more stuff in the string?
            str = *str_p;
            c = *str;
            if (endoflist(c)) {
                if (c) str++;
                *str_p = str;
                // nope, no more stuff
                break;
            }
        }
        x = Cons(x, NULL);
        result = Append(result, x);
    }
    return result;
}

#ifdef OPTIMIZE_LAMBDA
Cell *Contains(Cell *list, Cell *target) {
    if (!list) return NULL;
    if (Match(list, target)) {
        return target;
    }
    if (IsPair(list)) {
        Cell *r;
        
        r = Contains(Head(list), target);
        if (!r) r = Contains(Tail(list), target);
        return r;
    }
    return NULL;
}
#endif

// helper function for Lambda: lookup references when we can
static Cell *Compile(Cell *body, Cell *exclude, Cell *env) {
#ifdef OPTIMIZE_LAMBDA
    // we need to avoid capture of arguments
    // FIXME: what about defines within the body!?
    //        avoid that by just making define global
    Cell *r, *t, *h;
    if (!body) {
        return NULL;
    }
    if (GetType(body) == CELL_SYMBOL) {
        // avoid arg capture
        if (exclude && Contains(exclude, body)) {
            return body;
        }
        // OK, see if it's in the parent environment
        r = Lookup(body, env);
        if (r) {
            // note that this won't work if
            // the user has defined a local variable that shadows r
            // but is not a parameter; we work around this
            // by just disallowing it (let expands to a lambda,
            // so it's a parameter, and we've made define work
            // on the top level environment only)
            return r;
        }
    }
    if (IsPair(body)) {
        h = GetHead(body);
        t = GetTail(body);
        h = Compile(h, exclude, env);
        t = Compile(t, exclude, env);
        return Cons(h, t);
    }
#endif
    return body;
}

//
// lambda creates a function as follows:
// ( (args, env) body )
//

Cell *Lambda(Cell *args, Cell *body, Cell *env)
{
    Cell *descrip;
    Cell *oldenv = env;
    Cell *newenv = Cons(NULL, oldenv);
    Cell *r;

    // fixme some sanity checking here would be nice!
    descrip = Cons(args, newenv);
    // do any optimization we can
    body = Compile(body, args, newenv);
    // now create the pair
    r = AllocPair(CELL_FUNC, descrip, body);
    return r;
}

Cell *Eval(Cell *expr, Cell *env); // forward declaration

// evaluate each member of a list
// return a new list containing the evaluated values
Cell *EvalList(Cell *list, Cell *env)
{
    Cell *result;
    Cell *head;
    Cell *holder;
    Cell *cur;
    
    result = AllocPair(CELL_PAIR, 0, 0);
    
    while (list) {
        if (IsPair(list)) {
            head = Head(list);
            list = Tail(list);
        } else {
            head = list;
            list = NULL;
        }
        holder = AllocPair(CELL_PAIR, 0, 0);
        Append(result, holder);
        cur = Eval(head, env);
        SetHead(holder, cur);
    }
    return Tail(result);
}

static Cell *argMismatch()
{
    printcstr("argument mismatch\n");
    return NULL;
}
static Cell *applyCfunc(Cell *fn, Cell *args, Cell *env)
{
    LispCFunction *B;
    Cell *argv[MAX_C_ARGS];
    Cell *r;
    const char *argstr;
    int rettype;
    int c;
    int i = 0;
        
    if (fn == lc->globalQuote) {
        return args ? GetHead(args) : NULL;
    }
    B = GetTail(fn);
    argstr = B->args;
    rettype = *argstr++;
    // now extract arguments
    i = 0;
    while ( 0 != (c = *argstr++) && i < MAX_C_ARGS) {
        if (c == 'e') {
            argv[i++] = env;
            continue;
        }
        if (c == 'v') {
            argv[i++] = EvalList(args, env);
            args = NULL;
            continue;  // there may be an 'e' specification
        }
        argv[i] = args ? GetHead(args) : 0;
        if (islower(c)) {
            argv[i] = Eval(argv[i], env);
        }
        if (c == 'n') {
            if (IsNumber(argv[i])) {
                argv[i] = (Cell *)(intptr_t)GetNum(argv[i]);
            } else {
                return argMismatch();
            }
        }
        args = args? GetTail(args) : 0;
        i++;
    }
    /* are all arguments accounted for? */
    if (args) {
        return argMismatch();
    }
    r = (*B->func)(argv[0], argv[1], argv[2], argv[3]);
    if (rettype == 'n') {
        r = CNum((intptr_t)r);
    }
    return r;
}

static Cell *DefineOneArg(Cell *name, Cell *val, Cell *newenv, Cell *origenv)
{
    // special case: 'X means X gets the arg unevaluated
    if (Head(name) == lc->globalQuote) {
        name = Head(Tail(name));
    } else {
        val = Eval(val, origenv);
    }
    return doDefine(name, val, newenv);
}

static Cell *DefineArgs(Cell *names, Cell *args, Cell *newenv, Cell *origenv)
{
    Cell *name, *val;

    while (names && args) {
        name = Head(names); names = Tail(names);
        val = Head(args);  args = Tail(args);
        DefineOneArg(name, val, newenv, origenv);
    }
    if (names || args) {
        return argMismatch();
    }
    return lc->globalTrue;
}

static Cell *applyLambda(Cell *fn, Cell *args, Cell *env)
{
    Cell *newenv;
    Cell *body;
    Cell *argdescrip;

    newenv = GetHead(fn);
    body = GetTail(fn);
    argdescrip = GetHead(newenv);
    newenv = GetTail(newenv);
    newenv = AllocPair(CELL_PAIR, 0, GetTail(newenv));

    // now define arguments if we need to
    if (IsPair(argdescrip)) {
        if (Head(argdescrip) == lc->globalQuote) {
            // this one argument gets the whole list, unevaluated
            argdescrip = Tail(argdescrip);
            doDefine(Head(argdescrip), args, newenv);
        } else if (!DefineArgs(argdescrip, args, newenv, env)) {
            return NULL;
        }
    } else {
        // this argument gets the whole list, evaluated
        doDefine(argdescrip, EvalList(args, env), newenv);
    }
    return Eval(body, newenv);
}

Cell *Apply(Cell *fn, Cell *args, Cell *env)
{
    int typ;
    Cell *r;
    
    fn = Eval(fn, env);
    if (!fn) return NULL;
    typ = GetType(fn);
    if (typ == CELL_CFUNC) {
        r = applyCfunc(fn, args, env);
    } else if (typ == CELL_FUNC) {
        r = applyLambda(fn, args, env);
    } else {
        r = NULL;
    }
    return r;
}

Cell *Eval(Cell *expr, Cell *env)
{
    int typ;
    Cell *r;
    Cell *f, *args;

#ifdef __propeller__
    int c = peekchar();
    // the test below checks for either ^B or ^C
    if ( (c & 0xfe) == 2 ) {
        // break
        longjmp(break_buf, 1);
    }
#endif
    typ = GetType(expr);
    switch (typ) {
    case CELL_NUM:
    case CELL_STRING:
    case CELL_CFUNC:
    default:
        return expr;
    case CELL_SYMBOL:
        r = Lookup(expr, env);
        if (r) {
            r = GetTail(r);
        } else {
            r = undefSymbol(expr);
        }
        return r;
    case CELL_PAIR:
        f = GetHead(expr);
        args = GetTail(expr);
        return Apply(f, args, env);
    case CELL_REF:
        return GetTail(expr);
    }
}

Cell *Sequence(Cell *list, Cell *env)
{
    Cell *expr, *r;
    r = NULL;
    while (list) {
        expr = Head(list);
        list = Tail(list);
        r = Eval(expr, env);
    }
    return r;
}
        
Cell *If(Cell *cond, Cell *ifpart, Cell *elsepart, Cell *env) {
    if (cond) {
        return Eval(ifpart, env);
    } else {
        return Eval(elsepart, env);
    }
}

Cell *While(Cell *cond, Cell *body, Cell *env) {
    Cell *r = NULL;
    while (Eval(cond, env)) {
        r = Eval(body, env);
    }
    return r;
}

Cell *SetBang(Cell *name, Cell *val, Cell *env)
{
    Cell *x = Lookup(name, env);
    if (GetType(x) != CELL_REF) {
        return undefSymbol(name);
    }
    SetTail(x, val);
    return val;
}

int Plus(int x, int y) { return x+y; }
int Minus(int x, int y) { return x-y; }
int Times(int x, int y) { return x*y; }
int Div(int x, int y) { return x/y; }
int GCFree(void) { doGC(); return lc->freeCells; }

Cell *Lt(int x, int y) { return (x < y) ? lc->globalTrue : NULL; }
Cell *Le(int x, int y) { return (x <= y) ? lc->globalTrue : NULL; }
Cell *Gt(int x, int y) { return (x > y) ? lc->globalTrue : NULL; }
Cell *Ge(int x, int y) { return (x >= y) ? lc->globalTrue : NULL; }

Cell *Define(Cell *name, Cell *val) { return doDefine(name, val, lc->globalEnv); }

LispCFunction cdefs[] = {
    // quote must come first
    { "quote", "ccc", (GenericFunc)Quote },

    // remember: return val, then args in the C string
    { "lambda", "cCCe", (GenericFunc)Lambda },
    { "gcfree", "n", (GenericFunc)GCFree },
    { "eval", "cce", (GenericFunc)Eval },
    { "print", "cv", (GenericFunc)PrintList },
    { "define", "cCc", (GenericFunc)Define },
    { "number?", "cc", (GenericFunc)IsNumber },
    { "pair?", "cc", (GenericFunc)IsPair },
    { "begin", "cve", (GenericFunc)Sequence },
    { "while", "cCCe", (GenericFunc)While },
    { "if", "ccCCe", (GenericFunc)If },
    { "=", "ccc", (GenericFunc)Match },
    { "<>", "ccc", (GenericFunc)NoMatch },
    { "<", "cnn", (GenericFunc)Lt },
    { "<=", "cnn", (GenericFunc)Le },
    { ">", "cnn", (GenericFunc)Gt },
    { ">=", "cnn", (GenericFunc)Ge },
    { "append", "ccc", (GenericFunc)Append },
    { "cons", "ccc", (GenericFunc)Cons },
    { "head", "cc", (GenericFunc)Head },
    { "tail", "cc", (GenericFunc)Tail },
    { "set!", "cCce", (GenericFunc)SetBang },
    { "/", "nnn", (GenericFunc)Div },
    { "*", "nnn", (GenericFunc)Times },
    { "-", "nnn", (GenericFunc)Minus },
    { "+", "nnn", (GenericFunc)Plus },
    { NULL, NULL, NULL }
};

Cell *Lisp_DefineCFunc(LispCFunction *f)
{
    Cell *name, *val;
    name = CSymbol(f->name);
    val = NewCFunc(name, f);
    Define(name, val);
    return val;
}

Cell *
Lisp_Init(void *arena, size_t arenasize)
{
    LispCFunction *f;

    if (arenasize <= (4*sizeof(*lc))) {
        return NULL; // not nearly enough memory to be useful
    }
    lc = (struct LispContext *)arena;
    memset(lc, 0, sizeof(*lc));
    arenasize -= sizeof(*lc);
    InitGC((void *)(lc+1), arenasize);
    
    lc->globalEnv = Cons(NULL, NULL);
    lc->globalTrue = CString("#t");

    Define(CSymbol("#t"), lc->globalTrue);
    Define(CSymbol("nl"), CString("\n"));
    f = cdefs;
    lc->globalQuote = Lisp_DefineCFunc(f);
    f++;
    for (; f->name; f++) {
        if (!Lisp_DefineCFunc(f)) {
            return NULL;
        }
    }
    return lc->globalEnv;
}

#ifndef __propeller__
// useful for calling from gdb, so only for debugging
void debug(Cell *x) {
    Lisp_Print(x);
    printf("\n");
}
#endif

//
// run a lisp script
// (series of lisp expressions
//

Cell *Lisp_Eval(Cell *x) {
    return Eval(x, lc->globalEnv);
}

Cell *Lisp_Run(const char *buffer, int printIt)
{
    Cell *r = NULL;

#ifdef __propeller__
    if (setjmp(break_buf) != 0) {
        outstr("\r\nbreak");
        return NULL;
    }
#endif
    for(;;) {
        while (isspace(*buffer)) buffer++;
        if (!*buffer) break;
        r = ReadItemFromString(&buffer);
        r = Eval(r, lc->globalEnv);
        if (printIt) {
            Lisp_Print(r);
            printchar('\n');
        }
        // ignore spurious close parens
        while (*buffer == ')') buffer++;
    }
    return r;
}
