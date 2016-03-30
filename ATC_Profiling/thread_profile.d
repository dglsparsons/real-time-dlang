import realtime, interruptible_thread, 
       core.time, std.stdio, core.thread;

void main()
{
    setFIFOScheduler(95);
    Thread.getThis.priority = 90;

    Duration totalSetup; 
    Duration totalTeardown; 

    for(auto i = 0; i < 10_000; i++)
    {
        MonoTime timeCancelled;
        MonoTime timeAfter;
        MonoTime timeStarting;
        auto timeBefore = MonoTime.currTime;

        auto intr = new Interruptible({
            timeStarting = MonoTime.currTime; 
            while(true)
            {

            }
        });

        new Thread({
            timeCancelled = timeBefore + 10.msecs;
            delayUntil(timeCancelled); 
            intr.interrupt; 
        }).start;

        intr.start;
        timeAfter = MonoTime.currTime; 

        if (i % 10 == 0)
            writeln("Cancelled: ", i); 
        totalSetup += timeStarting - timeBefore; 
        totalTeardown += timeAfter - timeCancelled; 
    }

    writeln("Setup: ", totalSetup); 
    writeln("Teardown: ", totalTeardown); 
}
