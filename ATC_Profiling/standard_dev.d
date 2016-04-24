#!/usr/bin/rdmd 


import std.stdio, std.math, std.array, std.conv, std.string;//std.algorithm, std.conv;

immutable numtests = 10_000;

void main()
{
    auto my_array = stdin.byLineCopy();//each!writeln;;//to!"double".array;//to!"double".array;
    double total = 0;
    double[numtests] std_dev;
    int i = 0;
    foreach(line; my_array){
        std_dev[i] = (to!double(line.strip.dup) * 1_000_000);
        total += to!double(line.strip.dup) * 1_000_000;
        i++;
    }
    auto average = total / numtests;
    writeln("Average: ", total/numtests);

    double std_dev_total = 0; 
    foreach(num; std_dev){
        std_dev_total += (num - average).pow(2);
    }
    writeln("Standard Deviation: ", sqrt(std_dev_total / numtests));
}
