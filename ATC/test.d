import core.sys.posix.signal;
import core.thread;
import std.stdio; 

int n = 0; 

extern (C) void myhandler(int signum) nothrow
{
  printf("signal %d received - counter reset\n", signum);
  n = 0;
}

void main()
{
    sigaction_t action; 

    action.sa_handler = &myhandler; 

}
