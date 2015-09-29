import std.stdio; 
import core.thread; 
import std.concurrency; 

class myThread : Thread 
{
    this() {
        super(&run); 
    }

    private void run() {
        writeln("Hello, I am a new thread!"); 
        auto message = receiveOnly!string; 
        writeln("message: ", message); 
    }
}

void test()
{
    writeln("This shows creating the default thread class!"); 
}

void main()
{
    auto t = new Thread(&test).start; 
    auto testThread = new myThread();  
    testThread.start(); 
    writeln("Main thread!"); 
    //testThread.getThis.send("TestMessage"); 
}
