#!/usr/bin/rdmd 

import realtime, 
       core.time; 


void main()
{
    auto time = MonoTime.currTime; 
    time += 3.seconds; 
    delayUntil(time); 

}
