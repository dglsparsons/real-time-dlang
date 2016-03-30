import realtime, interruptible_exception, core.time, std.stdio, core.thread;


void main()
{
    setFIFOScheduler(95);
    Thread.getThis.priority = 90;

    Duration totalSetup; 
    Duration totalTeardown;

    for (auto i = 0; i < 10; i++)
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
            Thread.sleep(1.seconds); 
            intr.interrupt; 
            timeCancelled = MonoTime.currTime; 
        }).start;

        intr.start;
        timeAfter = MonoTime.currTime; 

        totalSetup += timeStarting - timeBefore;
        totalTeardown += timeAfter - timeCancelled;
    }

    writeln("Setup:    ", totalSetup); 
    writeln("Teardown: ", totalTeardown); 
}
