import realtime, interruptible_thread, core.time, std.stdio;

void intrFunction()
{
    while(true)
    {

    }
}


void main()
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

    writeln("Setup: ", timeDuring - timeBefore); 
    writeln("Teardown: ", timeAfter - timeDuring); 
}
