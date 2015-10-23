#!/usr/bin/rdmd

import std.stdio; 
import core.time; 

void main()
{
    auto time = MonoTime.currTime; 
    time += 3.seconds; 
    delay_until(time); 
    writeln("Delay Until is working!"); 
}

void delay_until(MonoTime timeIn)
{
    import core.sys.linux.time; 
    Duration dur = timeIn - MonoTime(0) ;
    long secs, nansecs; 
    dur.split!("seconds", "nsecs")(secs, nansecs); 
    timespec sleep_time = timespec(secs, nansecs); 
    if (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sleep_time, null))
        throw new Exception("Failed to sleep as expected!"); 
}
