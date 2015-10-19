#!/usr/bin/rdmd

import std.stdio; 
import core.sys.linux.time; 

void main()
{
    timespec current_time; 
    if (clock_gettime(CLOCK_MONOTONIC, &current_time)) {
        throw new Exception("Failed to get the time"); 
    }

    writeln("time: ", current_time); 
    current_time.tv_sec += 3; 
    writeln("time: ", current_time); 

    // This should be a 3 second sleep! 
    if (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &current_time, null))
        throw new Exception("Failed to sleep as expected!"); 
    writeln("Woken from sleep!"); 
}
