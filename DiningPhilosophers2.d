import std.stdio; 
import core.sync.semaphore; 
import core.thread; 
import std.parallelism;
import std.random;

immutable PHILOSOPHER_EAT_COUNT = 5; 

void main()
{
	immutable int[] philosophers = [0,1,2,3,4];
	Semaphore[philosophers.length] forks;
	foreach(ref fork; forks) 
		fork = new Semaphore(1); 
		
	foreach(phil; taskPool.parallel(philosophers)) {
		for(int i = 0; i < PHILOSOPHER_EAT_COUNT; i++){
			Thread.sleep(uniform(1,500).msecs);
			forks[phil].wait;
			forks[(phil+1)% 5].wait;
			writeln("philosopher: ", phil, " is eating, with forks ", phil, " and ", (phil+1)%5);
			Thread.sleep(uniform(1,500).msecs); 
			writeln("philosopher: ", phil, " has stopped eating");
			forks[(phil+1)%5].notify; 
			forks[phil].notify;
		} 
	}
}