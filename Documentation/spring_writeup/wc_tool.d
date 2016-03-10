#!/usr/bin/rdmd

import std.stdio, std.array, std.algorithm, std.file, std.string, std.regex,
       std.conv;

void main()
{
    uint count; 
    auto file = File("count.sum", "r");
    foreach(line; file.byLine) {
        string[] parts = split(line.idup);
        count += to!int(parts[3]);
    }
    writeln(count);
}
