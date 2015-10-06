import core.thread;
import std.stdio;

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
            writefln("A: %s", number);
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
    auto a = new AThread();
    a.priority = a.PRIORITY_MAX;
    auto b = new BThread();
    b.priority = b.PRIORITY_MIN;
    a.start();
    b.start();
}

