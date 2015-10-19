#!/usr/bin/rdmd

import std.stdio; 
import core.time; 
import core.sys.posix.time; 
import core.sys.linux.time; 


void main ()
{
    timespec CLOCK_Monotonic_Raw; 
    timespec Clock_RealTime_Coarse; 
    timespec Clock_Monotonic_Coarse; 
    timespec Clock_Boottime; 
    timespec Clock_Realtime_Alarm; 
    timespec Clock_Boottime_Alarm; 
    timespec Clock_SGI_Cycle;
    timespec Clock_TAI; 
    if (clock_gettime(CLOCK_MONOTONIC, &CLOCK_Monotonic_Raw)) {
        throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_REALTIME_COARSE, &Clock_RealTime_Coarse)) {
        throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_BOOTTIME, &Clock_Boottime)) {
        throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_REALTIME_ALARM, &Clock_Realtime_Alarm)) {
        throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_BOOTTIME_ALARM, &Clock_Boottime_Alarm)) {
        throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_SGI_CYCLE, &Clock_SGI_Cycle)) {
        //throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_MONOTONIC_COARSE, &Clock_Monotonic_Coarse)) {
        throw new Exception("Failed to get the time"); 
    }
    if (clock_gettime(CLOCK_TAI, &Clock_TAI)) {
        throw new Exception("Failed to get the time"); 
    }
    writeln("CLOCK_MONOTONIC_RAW: ", CLOCK_Monotonic_Raw); 
    writeln("CLOCK_MONOTONIC_COARSE: ", Clock_Monotonic_Coarse); 
    writeln("CLOCK_REALTIME_COARSE: ", Clock_RealTime_Coarse); 
    writeln("CLOCK_BOOTTIME: ", Clock_Boottime); 
    writeln("Clock_Realtime_Alarm: ", Clock_Realtime_Alarm);
    writeln("Clock_Boottime_Alarm: ", Clock_Boottime_Alarm); 
    writeln("Clock_SGI_Cycle: ", Clock_SGI_Cycle);
    writeln("Clock_TAI: ", Clock_TAI); 
}
