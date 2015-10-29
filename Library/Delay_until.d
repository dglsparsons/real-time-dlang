#!/usr/bin/rdmd 

import RealTime, 
       core.time; 


void main()
{
    auto time = MonoTime.currTime; 
    time += 3.seconds; 
    delay_until(time); 

}
