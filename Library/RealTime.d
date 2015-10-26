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
 * 
 * Note: 
 * In order for clock_nanosleep() to be called, this was added to the core
 * druntime under CRuntime_Glibc. 
 */

void delay_until(MonoTime timeIn)
{
    version(Posix) {
        import core.sys.linux.time; 
        Duration dur = timeIn - MonoTime(0) ;
        long secs, nansecs; 
        dur.split!("seconds", "nsecs")(secs, nansecs); 
        timespec sleep_time = timespec(secs, nansecs); 
        if (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sleep_time, null))
            throw new Exception("Failed to sleep as expected!"); 
    }
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
 *  Also: Testing on Arch Linux, it appears SCHED_BATCH and SCHED_IDLE are not
 *  present?
 */

void setScheduler(int scheduler_type, int scheduler_priority)
{
    version(Posix){
        import core.sys.posix.sched; 
        sched_param sp = { sched_priority: scheduler_priority }; 
        int ret = sched_setscheduler(0, scheduler_type, &sp); 
        if (ret == -1) {
            throw new Exception("scheduler did not properly set");
        }
    }
}

unittest 
{
    import core.sys.posix.sched; 
    setScheduler(SCHED_FIFO, 50); 
    auto a = sched_getscheduler(0); 
    assert(a == SCHED_FIFO); 
    setScheduler(SCHED_RR, 50); 
    a = sched_getscheduler(0); 
    assert(a == SCHED_RR); 
    /*
    setScheduler(SCHED_BATCH); 
    a = sched_getscheduler(0); 
    assert(a == SCHED_BATCH); 
    setScheduler(SCHED_IDLE); 
    a = sched_getscheduler(0); 
    assert(a == SCHED_IDLE); 
    */
}

// TODO - THREAD FIXES NEEDED - Thread.PRIORITY_MAX and Thread.PRIORITY_MIN are not
// being correctly set. In addition it is not possible to set the priority of a thread
// until it is running - Does this need fixing? 

enum PRIORITY_INHERIT = 2; 
enum PRIORITY_CEILING = 3; 

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
 *  PRIORITY_INHERIT or PRIORITY_CEILING. Passing in 0 will initialise the
 *  mutex with neither protocol. 
 *
 *  Example: 
 *  ---
 *  auto a = new RTMutex(PRIORITY_INHERIT); 
 *  ---
 *
 *  Note: 
 *  In order for RTMutex to function properly, the Mutex attribute m_hndl was
 *  modified within druntime. This was changed from private, to protected,
 *  enabling RTMutex to access it through the constructor. 
 *  It would also be possible to not need these modifications by defining
 *  RTMutex as a separate class, and defining any methods needed here. 
 * 
 *  Further Note: 
 *  In order to provide support for priority ceiling/ inheritance protocols, a
 *  modification was made to the druntime. 
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
                throw new SyncError("Unable to initialize Mutex"); 

            if(pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE))
                throw new SyncError("Unable to initialize mutex");

            if(type == PRIORITY_CEILING)
            {
                if(pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_PROTECT))
                    throw new SyncError("Unable to initialize Priority ceiling protocol"); 
            }
            else if (type == PRIORITY_INHERIT)
            {
                if(pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT))
                    throw new SyncError("Unable to initialize Priority inheritance protocol"); 
            }

            if( pthread_mutex_init(&m_hndl, &attr))
            {
                throw new SyncError("Unable to initialize mutex");
            }
        }
    }

    /**
     * Gets the priority ceiling for the associated mutex. 
     * 
     * Returns: 
     *  The priority ceiling of this thread.
     * 
     * Example: 
     * ---
     * auto a = new RTMutex(PRIORITY_CEILING); 
     * int currentPriorityCeiling = a.ceiling();
     * ---
     */
    final @property int ceiling()
    {
        version(Posix)
        {
            int ceiling; 
            if(pthread_mutex_getprioceiling(&m_hndl, &ceiling))
                throw new SyncError("Unable to fetch the priority ceiling for the associated Mutex"); 
            return ceiling; 
        }
    }

    /**
     * Sets the priority ceiling for the associated mutex. 
     * 
     * Params: 
     *  val = The new priority ceiling of this mutex
     *
     * Example: 
     * ---
     * auto a = new RTMutex(PRIORITY_CEILING); 
     * int newCeiling = 50; 
     * a.ceiling(newCeiling); 
     * ---
     */
    final @property void ceiling(int val)
    {
        version(Posix)
        {
            if(pthread_mutex_setprioceiling(&m_hndl, val, null))
                throw new SyncError("Unable to set the priority ceiling for the associated Mutex"); 
        }
    }
}

unittest 
{
    auto a = new RTMutex(PRIORITY_CEILING); 
    int prio = 50; 
    a.ceiling(prio); 
    assert(prio == a.ceiling); 
    int newPrio = 25; 
    a.ceiling(newPrio); 
    assert(prio != a.ceiling); 
    assert(newPrio == a.ceiling); 
}
