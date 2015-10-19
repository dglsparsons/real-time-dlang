#include <time.h>
#include <stdio.h> 

int main()
{
    timespec ts; 
    printf("Clock: %s\r\n", clock_gettime(CLOCK_MONOTONIC)); 
}
