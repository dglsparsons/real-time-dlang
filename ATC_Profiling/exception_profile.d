import realtime, interruptible_exception, 
       core.time, std.stdio, core.thread, std.math, core.memory;

immutable auto numtests = 10_000;

void main()
{
    setFIFOScheduler(95);
    Thread.getThis.priority = 90;

    Duration totalSetup; 
    Duration totalTeardown;
    Duration setupTimes[numtests];
    Duration teardownTimes[numtests];

    for (auto i = 0; i < numtests; i++)
    {
        GC.collect;
        MonoTime timeCancelled;
        MonoTime timeAfter;
        MonoTime timeStarting; 

        auto timeBefore = MonoTime.currTime;

        auto intr = new Interruptible({
            getInt.deferred = true;
            timeStarting = MonoTime.currTime;
            while(true)
            {
                getInt.testCancel;
            }
        });

        new Thread({
            timeCancelled = timeBefore + 10.msecs;
            delayUntil(timeCancelled); 
            intr.interrupt; 
        }).start;

        intr.start;
        timeAfter = MonoTime.currTime; 

        setupTimes[i] = timeStarting - timeBefore;
        teardownTimes[i] = timeAfter - timeCancelled;
        totalSetup += setupTimes[i]; 
        totalTeardown += teardownTimes[i];
    }

    writeln("Average Setup:    ", totalSetup / numtests); 
    writeln("Average Teardown: ", totalTeardown / numtests); 

    double totalVariance = 0; 
    foreach(time; setupTimes)
    {
        totalVariance += (time - (totalSetup/numtests)).abs.total!"usecs".pow(2);
    }
    writeln("Standard deviation of setup: ", sqrt(totalVariance /numtests));

    totalVariance = 0;

    foreach(int i, time; teardownTimes)
    {
        totalVariance += (time - (totalSetup/numtests)).abs.total!"usecs".pow(2);
    }
    writeln("Standard deviation of teardown: ", sqrt(totalVariance /numtests));
}
