#!/usr/bin/rdmd

import std.stdio; 
import std.concurrency; 
import core.thread; 

immutable int NUMBER_OF_SEATS = 5;
immutable int PHILOSOPHER_EAT_COUNT = 5; 
immutable int totalEatingCount = PHILOSOPHER_EAT_COUNT * NUMBER_OF_SEATS; 
 

void main()
{
	Chopstick[NUMBER_OF_SEATS] chopsArray;
	Tid[NUMBER_OF_SEATS] threadArray;  
	for (int i = 0; i < NUMBER_OF_SEATS; i++) {
		chopsArray[i] = new Chopstick(); 
		threadArray[i] = spawn(&philosopherThread, i);
	}
	
	int endCount = 0;
	while ( endCount < totalEatingCount ) { // main loop
		auto message 	= receiveOnly!(string,int,int);
		auto command 	= message[0]; 
		auto leftStick  = message[1]; 
		auto rightStick = message[2];
		
		if (command == "request") {
			// philosopher is requesting his chopsticks 
			if (chopsArray[leftStick].free && chopsArray[rightStick].free) {
				chopsArray[leftStick].free = false; 
				chopsArray[rightStick].free = false;
				writeln("Given chopsticks ", leftStick," and ", rightStick, " to philosopher: ", leftStick);  
				threadArray[leftStick].send(true); 
			} else {
				threadArray[leftStick].send(false);
			}
		} else if (command == "return") {
			// philosopher is returning his chopsticks
			writeln("Philosopher ", leftStick, " has stopped eating");
			chopsArray[leftStick].free = true; 
			chopsArray[rightStick].free = true; 
			endCount++;
		}
	}
	thread_joinAll; 
}

void philosopherThread (int index)
{
	auto leftStick = index;
	auto rightStick = (index+1) % NUMBER_OF_SEATS;
	
	int successfulEatCount; 
	while(successfulEatCount < PHILOSOPHER_EAT_COUNT) {
		bool canPickupForks = false;
		// Philosopher thinks for a while 
		Thread.sleep(200.msecs);
		ownerTid.send("request", leftStick, rightStick);
		// wait for the response - letting us know we can eat. 
		canPickupForks = receiveOnly!bool;
		if (canPickupForks) {
			writeln("Philosopher ", index, " is eating");  
			Thread.sleep(200.msecs); 
			
			ownerTid.send("return", leftStick, rightStick);
			successfulEatCount++; 
		} 
	}
	writeln("Philosopher: ", leftStick, " has finished eating for good!");
}

class Chopstick
{
	bool free;
	this(){ 
		free = true; 
	}
}
