#!/usr/bin/rdmd
import std.stdio; 
import core.sync.semaphore; 
import core.thread; 
import std.parallelism;
import std.random;

immutable PHILOSOPHER_EAT_COUNT = 5; 
immutable NUMBER_OF_PHILOSOPHERS = 4; 

void main()
{
	immutable int[] philosophers = [0,1,2,3];
	Semaphore[philosophers.length] forks;
	foreach(ref fork; forks) 
		fork = new Semaphore(1); 
		
	foreach(phil; taskPool.parallel(philosophers)) {
        writeln("STARTING THREAD FOR PHIL: ", phil); 
		for(int i = 0; i < PHILOSOPHER_EAT_COUNT; i++){
			Thread.sleep(uniform(1,500).msecs);
			bool holdForks = false; 
			while(!holdForks) {
				holdForks = Monitor.requestForks(forks[phil], forks[(phil+1)%NUMBER_OF_PHILOSOPHERS]);
			}
			writeln("philosopher: ", phil, " is eating, with forks ", phil, " and ", (phil+1)%NUMBER_OF_PHILOSOPHERS);
			Thread.sleep(uniform(1,500).msecs); 
			writeln("philosopher: ", phil, " has stopped eating");
			forks[(phil+1)%NUMBER_OF_PHILOSOPHERS].notify; 
			forks[phil].notify;
		} 
        writeln("PHILOSOPHER ", phil, " HAS STOPPED EATING FOR GOOD"); 
	}
}

static class Monitor
{
	static synchronized bool requestForks(Semaphore leftFork, Semaphore rightFork)
	{
		bool holdingLeftFork  = leftFork.tryWait;
		bool holdingRightFork = rightFork.tryWait;
		if (holdingLeftFork && holdingRightFork) {
			return true; 
		} else if (holdingLeftFork) {
			leftFork.notify;
		} else if (holdingRightFork) {
			rightFork.notify; 
		}
		return false; 
	}
	
	
}
