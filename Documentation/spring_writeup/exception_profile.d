import realtime, interruptible_exception, 
       core.time, std.stdio, core.thread;

immutable auto numtests = 10_000;

void main()
{
    setFIFOScheduler(95);
    Thread.getThis.priority = 90;

    Duration totalSetup; 
    Duration totalTeardown;

    for (auto i = 0; i < numtests; i++)
    {
        MonoTime timeCancelled;
        MonoTime timeAfter;
        MonoTime timeStarting; 
        auto timeBefore = MonoTime.currTime;

        auto intr = new Interruptible({
            timeStarting = MonoTime.currTime;
            while(true){}
        });

        new Thread({
            timeCancelled = timeBefore + 10.msecs;
            delayUntil(timeCancelled); 
            intr.interrupt; 
        }).start;

        intr.start;
        timeAfter = MonoTime.currTime; 

        totalSetup += timeStarting - timeBefore;
        totalTeardown += timeAfter - timeCancelled;
    }

    writeln("Average Setup:    ", totalSetup / numtests); 
    writeln("Average Teardown: ", totalTeardown / numtests); 
}
