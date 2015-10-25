module realtime; 

import core.time; 

/** 
 * Implementation of a non-relative delay function. 
 * This is needed in real time systems for periodic tasks to guarantee they 
 * are woken at the correct time. 
 * Regular sleep is not sufficient for this, as may be preempted in between 
 * calculating the time to sleep, and beginning sleeping. 
 *
 * Example: 
 * ---
 * auto time = MonoTime.currTime; 
 * time += 3.seconds; 
 * delay_until(time); 
 * ---
 */

void delay_until(MonoTime timeIn)
{
    import core.sys.linux.time; 
    Duration dur = timeIn - MonoTime(0) ;
    long secs, nansecs; 
    dur.split!("seconds", "nsecs")(secs, nansecs); 
    timespec sleep_time = timespec(secs, nansecs); 
    if (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sleep_time, null))
        throw new Exception("Failed to sleep as expected!"); 
}


/** 
 *  The following function provides a wrapper for POSIX system calls, in order 
 *  to set the system scheduler. 
 *  This is required in Real time systems in order to schedule tasks according 
 *  to priorities. 
 *  Regular scheduling is insufficient here, as there are no guarantees on which 
 *  order threads will execute. The default scheduler instead favours a "fair" approach. 
 *
 *  Params: 
 *  int scheduler_type = the type of scheduler to set. values can be: 
 *  SCHED_OTHER, SCHED_BATCH, SCHED_IDLE, or for Real Time applications: SCHED_FIFO and SCHED_RR
 *  int scheduler_priority = the priority of the scheduler.
 *
 *  Example: 
 *  ---
 *  setScheduler(SCHED_FIFO, 50); 
 *  ---
 *
 *  Note:
 *  Depending on the distribution of linux, the program may require root
 *  priveledges in order to change its scheduler. 
 */

void setScheduler(int scheduler_type, int scheduler_priority)
{
    import core.sys.posix.sched; 
    sched_param sp = { sched_priority: scheduler_priority }; 
    int ret = sched_setscheduler(0, scheduler_type, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
}
