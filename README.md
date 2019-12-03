# si78c

`si78c` is a memory accurate reimplementation of the 1978 arcade game Space Invaders in C.

It requires the original arcade ROM to function to load various sprites and
other data, but does not use the original game code.

It is not an emulation, but rather a restoration.

It is however, accurate enough that it can be used to understand the inner
workings of the original system, in a more accessible manner.

Many thanks to Christopher Cantrell at computerarcheology.com. Without his
painstaking work and excellent notes, this project would have taken a lot
longer.

# Project Scale

This was a reasonably large undertaking, requiring many iterations over several
months, and I would conservatively estimate that around 200 hours of work have
been put into the project so far.

The original ROM is around 2000 lines of 8085 assembler, all of it game code.
The final published version of `si78c` is around 1500 lines of game code, 500
lines of support code, and around 800 lines of comments.

There are about twenty thousand more lines of unpublished code in the
background consisting of the previous iterations and other support scripts
and tools that needed to be written to get the job done.

# Accuracy

When running, `si78c` produces identical memory states (apart from the stack) to
the original version. As a natural side effect, it produces pixel accurate
frames compared to the original.

Cycle timing is not particularly accurate, but the game code is not
particularly sensitive to this, as it uses interrupts for timing most
things, instead of clock cycles.

# Audience

The intended audience is hackers, enthusiasts, scholars, students, historians,
and anyone else engaged in digital archaeology.

The code is intended to be used as a more accessible guide to studying the
original game, and learning about its inner workings.

# Conventions

Where practical, I have used the same or similar function and variable names as
Cantrell, to more easily aid people studying both versions. The code is also
laid out in a similar order to the original.

Every function with a matching analog in the original system is signposted
with a comment like `xref 028e`, which gives the address of the matching routine
in the original ROM.

A few other places in the code like loops and branches are annotated similarly.

To find more detail on code near an xref, you can use Cantrell's
excellent notes [here](https://computerarcheology.com/Arcade/SpaceInvaders/Code.html).

# Threading

The original code is interrupt driven, and partially co-operatively
multitasked. The game spends about a third of the time running the main
thread, which gets pre-empted by the midscreen and vblank interrupts. The other
two thirds of the time is split between those interrupt contexts, which are not
pre-empted, but decide when to return to main.

It also contains some interesting parts like this:

```
02D0: 31 00 24        LD      SP,$2400         // wipe the stack
02D3: FB              EI                       // drop isr context
02D4: CD D7 19        CALL    DsableGameTasks  // keep going from this point
```

That code (running in an interrupt context) after detecting the player's death,
essentially wipes out all thread contexts (including itself), and then becomes
the new main context.

To handle things like this in the this in si78c, I decided to use `ucontext`
(user level threading) to give me more fine grained control over thread
switching, creation and destruction.

The equivalent piece of code in C to the above is a bit messier, and involves
using `swapcontext` to swap to a scheduler context, which then resets all the
contexts, and then swaps back and re-enters at the desired point.

# Limitations

There is no sound, as the sound hardware is not emulated.

Cycle timing is not particularly accurate, as mentioned, but its not very
important in this case.

The code will currently only work on little endian systems, as the original
system (8085) was little endian, and we use the ROM data as is.

# Porting

The game is known to build and run on Ubuntu 18.04 and MacOSX El Capitan, and
will likely run on other x86 Unix systems, as long as they support `ucontext` and
`SDL2`. Unfortunately, `ucontext` is deprecated on MacOSX, so it may not run on
later versions.

The game is written in the subset of C99 that is compatible with C++, and uses
no compiler extensions apart from attribute packed. It will build fine on GCC 3
and above, and most likely any Unix C or C++ compiler newer than that.

Porting to a non unix system like Windows would require changing out `ucontext`
to use threads or fibers. Porting to a simpler system like DOS, or something
bare metal will require writing some code to blit to the framebuffer, and
adapting to whatever native interrupt facilities are available.

In terms of CPU grunt required, the code isn't particularly optimized, and
currently requires a 32-bit processor capable of at least 10 Mips. It could be
made to fit on a smaller system with a bit of work.

The code assumes little endian. To port to a big endian system would require
further dissection of the ROM, to identify and swizzle any little endian data
when it is loaded.

Porting the code to another language would not be a small task, and would most
likely require switching out the threading system, and converting the code to
not use pointers.

# Building and running

`SDL2` is required as a dependency, to install on Ubuntu, do this:

    $ sudo apt-get install libsdl2

To grab the code and build the binary, do this:

    $ git clone https://github.com/loadzero/si78c.git && cd si78c
    $ make

As mentioned, the original arcade ROM is required, `invaders.zip` from the
`MAME_078` set is known to work.

The constituent parts must be placed in a folder called `inv1`, and have
these checksums:

    $ md5sum inv1/*

    7d3b201f3e84af3b4fcb8ce8619ec9c6  inv1/invaders.e
    7709a2576adb6fedcdfe175759e5c17a  inv1/invaders.f
    9ec2dc89315a0d50c5e166f664f64a48  inv1/invaders.g
    e87815985f5208bfa25d567c3fb52418  inv1/invaders.h

To run it:

    $ ./bin/si78c

The keyboard controls are:

    a   LEFT
    d   RIGHT
    1   1P
    2   2P
    j   FIRE
    5   COIN
    t   TILT

