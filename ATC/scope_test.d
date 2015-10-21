
import core.thread; 
import std.stdio; 
import core.sync.mutex; 

__gshared Mutex mut; 

void main()
{
    mut = new Mutex(); 
    new Thread(&threadFunc).start(); 
    Thread.sleep(1.seconds); 
    writeln("Main thread waiting for mutex"); 
    mut.lock(); 
    mut.unlock(); 
}


void threadFunc()
{
    mut.lock(); 
    scope(exit) mut.unlock; 

    Thread.sleep(5.seconds); 
    writeln("New thread crashing!"); 
    throw new Exception("Oops"); 
}
