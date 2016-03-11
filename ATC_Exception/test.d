#!/usr/bin/rdmd 

import interruptible, std.stdio, core.thread; 


void abortable()
{
    while(true) 
        writeln(" "); 
}


void main()
{

    auto a = new Interruptible(&abortable); 
    new Thread({
        Thread.sleep(1.seconds); 
        a.interrupt;
    }).start;
    a.start();

}
