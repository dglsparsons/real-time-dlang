import std.stdio; 
import core.sync.semaphore; 
import core.thread; 
import std.parallelism;
import std.random;

immutable int NUMBER_OF_SEATS = 5; 
immutable int PHILOSOPHER_EAT_COUNT = 5; 

void main()
{
	const philosophers = [0,1,2,3,4];
	writeln(philosophers.length);
    Semaphore[philosophers.length] forks;
	foreach(ref fork; forks) 
		fork = new Semaphore(1); 
	foreach(i, philosopher; taskPool.parallel(philosophers)) {
		while(true){
			Thread.sleep(uniform(1,500).msecs);
			forks[i].wait;
			forks[(i+1)% 5].wait;
			writeln("philosopher: ", philosopher, " is eating, with forks ", i, " and ", (i+1)%5);
			Thread.sleep(uniform(1,500).msecs); 
			writeln("philosopher ", philosopher, " has stopped eating");
			forks[(i+1)%5].notify;
			forks[i].notify;
		} 
	}
}