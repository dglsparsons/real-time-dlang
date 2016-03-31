import realtime, interruptible_exception, 
       core.time, std.stdio, core.thread, 
       core.memory; 

immutable auto numtests = 10_000;

void main()
{
    setFIFOScheduler(95);
    Thread.getThis.priority = 90;

    Duration totalSetup; 
    Duration totalTeardown;
    MonoTime timeStarting; 
    MonoTime timeCancelled;
    MonoTime timeAfter;
    MonoTime timeBefore;

    auto interruptibleSection = new Interruptible({
        timeStarting = MonoTime.currTime;
        while(true){}
    });

    auto timeoutThread = new Thread({
            timeCancelled = timeBefore + 20.msecs; 
            delayUntil(timeCancelled); 
            interruptibleSection.interrupt; 
            });

    for (auto i = 0; i < numtests; i++)
    {
        timeBefore = MonoTime.currTime;

        timeoutThread.start;
        interruptibleSection.start;

        timeAfter = MonoTime.currTime; 
        if (i % 100 == 0)
            writeln("Completed: ", i);

        totalSetup += timeStarting - timeBefore;
        totalTeardown += timeAfter - timeCancelled;
        GC.collect;
    }

    writeln("Average Setup:    ", totalSetup / numtests); 
    writeln("Average Teardown: ", totalTeardown / numtests); 
}
