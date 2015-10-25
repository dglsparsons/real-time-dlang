//module realtime; 

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



// TODO - THREAD FIXES NEEDED - Thread.PRIORITY_MAX and Thread.PRIORITY_MIN are not
// working. In addition it is not possible to set the priority of a thread
// until it is running - This needs fixing??? -- PRIORITY_MAX and PRIORITY_MIN
// are in an set of code that never gets called for POSIX? - BUG IN THE
// RUNTIME?


// There might be a tidier way to implement a Mutex with Priority Inheritance
// or Priority Inversion than this. It is quite messy. :(

immutable int PRIORITY_INHERIT = 0; 
immutable int PRIORITY_CEILING = 1; 

/** 
 *  The following function provides additional functionality compared to the
 *  standard Mutex. In addition to providing mechanisms for lock/unlock,
 *  RTMutex contains support for priority inversion through the priority inheritance or 
 *  priority ceiling protocols. 
 *  This is required in Real time systems in order to prevent priority
 *  inversion from occuring when accessing shared resources. 
 *
 *  Params: 
 *  int type = This determines whether the mutex created will use the priority
 *  inheritance or the priority ceiling protocol. Values can be
 *  PRIORITY_INHERIT or PRIORITY_CEILING. 
 *
 *  Example: 
 *  ---
 *  auto a = new RTMutex(PRIORITY_INHERIT); 
 *  ---
 *
 *  Note:
 *  TODO - Provide a nice interface for getting and setting the priority
 *  ceiling of the mutex, if using the ceiling protocol. 
 */

import core.sync.mutex; 
class RTMutex : Mutex 
{
    version(Posix)
    {
        import core.sys.posix.pthread; 
        this(int type) nothrow @trusted
        {
            pthread_mutexattr_t attr = void; 

            if(pthread_mutexattr_init(&attr))
            {
                throw new SyncError("Unable to initialize Mutex"); 
            }

            if(pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE))
            {
                throw new SyncError("Unable to initialize mutex");
            }
            if(type)
            {
                if(pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_PROTECT))
                {
                    throw new SyncError("Unable to initialize Priority ceiling protocol"); 
                }
            }
            else 
            {
                if(pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT))
                {
                    throw new SyncError("Unable to initialize Priority inheritance protocol"); 
                }
            }

            if( pthread_mutex_init(&m_hndl, &attr))
            {
                throw new SyncError("Unable to initialize mutex");
            }
        }
    }
}


