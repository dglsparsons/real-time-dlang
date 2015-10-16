
import core.sys.posix.sched; 

/*
   Sets the scheduler type according to the ENUM, and priority passed in. 
   SCHED_OTHER
   SCHED_FIFO
   SCHED_RR
 */

void setScheduler(int scheduler_type, int scheduler_priority)
{
    sched_param sp = { sched_priority: scheduler_priority }; 
    int ret = sched_setscheduler(0, scheduler_type, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
}
