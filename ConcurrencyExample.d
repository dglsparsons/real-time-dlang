#!/usr/bin/rdmd

import std.stdio; 
import core.thread; 
import std.concurrency; 

void main()
{
    writeln("Starting new thread"); 
    auto myThread = spawn(&myThreadFunction); 
    //Thread.sleep(200.msecs); 
    writeln("Sending message"); 
    myThread.send(42); 
    myThread.send("Hello, new thread!"); 
    writeln("Message has been sent"); 
}

void myThreadFunction()
{
    writeln("New thread started: "); 
    Thread.sleep(200.msecs);
    string message = "Nothing receieved"; 
    auto received = receiveTimeout(0.msecs, 
            (string rec) { message = rec; } 
            ); 
    writeln("message receieved: ", message); 
}
