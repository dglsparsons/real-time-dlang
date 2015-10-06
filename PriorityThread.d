import core.thread;
import std.stdio;
import core.sys.posix.sched; 
import std.process; 

class AThread : Thread
{
    this()
    {
        super(&run);
    }

    private:
    void run()
    {
        foreach (number; 1..1000) {
            //writefln("B: %s", number);
        }
    }
}


class BThread : Thread
{
    this()
    {
        super(&run);
    }

    private:
    void run()
    {
        foreach (number; 1..1000) {
            writefln("B: %s", number);
        }
    }
}


void main()
{
    sched_param sp = { sched_priority : 50 };
    int ret = sched_setscheduler(0, SCHED_FIFO, &sp); 
    if (ret == -1) {
        writeln("crap");
    }
    auto a = new AThread();
    //a.priority = a.PRIORITY_MAX;
    //auto b = new BThread();
//    b.priority = b.PRIORITY_MIN;
    a.start();
    //b.start();
}

