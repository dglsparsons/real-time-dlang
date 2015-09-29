import std.stdio; 
import std.concurrency; 
import core.thread; 

void main()
{
	Chopstick[5] chopsArray;
	Tid[5] threadArray;  
	for (int i = 0; i < 5; i++) { 
		chopsArray[i] = new Chopstick(i); 
	} 
	// initialise all the philosophers
	for (int i = 0; i < 5; i++) {
		threadArray[i] = spawn(&philosopherThread, i);
	}
	// listen for a request or a release of chopsticks.
	while(1) {
		auto message = receiveOnly!(string,int,int);
		auto command = message[0]; 
		auto leftStick = message[1]; 
		auto rightStick = message[2];
		 
		if (command == "request") {
			// if both sticks are free, we can give them to him. 
			if (chopsArray[leftStick].free && chopsArray[rightStick].free) {
				// mark the chopsticks as in use
				chopsArray[leftStick].free = false; 
				chopsArray[rightStick].free = false;
				writeln("Given chopsticks ", leftStick," and ", rightStick, " to philosopher: ", leftStick);  
				// signal that the philosopher can eat
				threadArray[leftStick].send(true); 
			} else {
				threadArray[leftStick].send(false); 
			}
		} else if (command == "return") {
			writeln("Philosopher ", leftStick, " has stopped eating");
			chopsArray[leftStick].free = true; 
			chopsArray[rightStick].free = true; 
		}
	}
}

void philosopherThread (int index)
{
	auto leftStick = index;
	auto rightStick = (index+1) % 5;
	// message the main thread asking for the sticks. 
	for (int i = 0;; i++ ){
		bool canPickupForks = false;
		// Think for a while 
		Thread.sleep(200.msecs);   
		while (!canPickupForks) {
			ownerTid.send("request", leftStick, rightStick);
			// wait for the response - letting us know we can eat. 
			canPickupForks = receiveOnly!bool;
		}
		// now we have the chopsticks, eat.
		writeln("Philosopher ", index, " is eating");  
		Thread.sleep(200.msecs); 
		// now give back the sticks
		ownerTid.send("return", leftStick, rightStick);
	}
}

class Chopstick
{
	private int id; 
	private bool free;
	this(int index){
		id = index; 
		free = true; 
	}
}