import realtime, interruptible_exception, core.time, std.stdio, core.thread;

void intrFunction()
{
    while(true)
    {

    }
}

void main()
{
    setFIFOScheduler(95);
    Thread.getThis.priority = 90;

    Duration totalSetup; 
    Duration totalTeardown;

    for (auto i = 0; i < 10; i++)
    {
        MonoTime timeDuring;
        MonoTime timeAfter;
        auto timeBefore = MonoTime.currTime;
        auto intr = new Interruptible(&intrFunction); 
        new Thread({
            Thread.sleep(1.seconds); 
            intr.interrupt; 
            timeDuring = MonoTime.currTime; 
        }).start;
        intr.start;
        timeAfter = MonoTime.currTime; 

        totalSetup += timeDuring - timeBefore - 1.seconds;
        totalTeardown += timeAfter - timeDuring;
    }

    writeln("Setup:    ", totalSetup); 
    writeln("Teardown: ", totalTeardown); 
}
