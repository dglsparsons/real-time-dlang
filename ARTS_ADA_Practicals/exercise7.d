#!/usr/bin/rdmd

import std.stdio,
       core.thread,
       RealTime;

__gshared MonoTime start_time; 

void periodicFunction()
{
    Thread.getThis.priority = Thread.PRIORITY_MIN + 5;
    auto release_interval = 100.msecs;
    auto next_release = start_time;
    for (int i = 1; i <= 100; i++)
    {
        delay_until(next_release);
        writeln("Periodic Task: ", i); 
        next_release += release_interval; 
    }
}

void workerFunction()
{
    Thread.getThis.priority = Thread.PRIORITY_MIN + 1;
    int F;
    int I;
    delay_until(start_time);
    while(true)
    {
        writeln("Task 2 executing");
        for (int i =0; i < 10000000; i++)
        {
            F += i * 10;
        }

        I += 1;
        if ( I == 50)
        {
            break;
        }
    }
    writeln("Task 2 terminating");
}

void main()
{
    // set the scheduler
    setScheduler(SCHED_FIFO, 50);

    start_time = MonoTime.currTime() + 100.msecs;

    // periodic task
    new Thread(&periodicFunction).start;

    // worker task
    new Thread(&workerFunction).start;

    // wait until completed
    thread_joinAll;
}
