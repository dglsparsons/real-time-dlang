

private import core.time;
private import core.thread : Thread;

/** 
 * delayUntil is an implementation of a non-relative sleep function. 
 * This is needed in real-time systems in order to ensure exact timings are
 * met. Regular Thread.sleep is not sufficient for this, as calculations of
 * how long to sleep for may be preempted. This would cause a delayed call to
 * sleep, making the calculation inaccurate. 
 * <p>
 * delayUntil should always be called with a MonoTime. Access to a monotonic
 * clock is a requirement of a real-time system. This provides a dependable
 * interval.
 * 
 * Params: 
 * MonoTime time = the absolute time to wait until before progressing. 
 *
 * Example: 
 * ---
 * auto time = MonoTime.currTime; 
 * time += 100.msecs;
 * delayUntil(time);
 * --- 
 * 
 * Note: 
 * This function depends on the glibc function, clock_nanosleep(), imported
 * below. If this is missing from the target platform, then delayUntil will
 * not correctly function. 
 **/

extern (C) nothrow @nogc
{
    private import core.sys.posix.signal : timespec; 
    alias int clockid_t; 
    int clock_nanosleep(clockid_t, int, in timespec*, timespec*);
}

void delayUntil(MonoTime timeIn)
{
    import core.sys.linux.time,
           core.time : Duration, timespec; 

    Duration dur = timeIn - MonoTime(0); 
    long secs, nansecs; 
    dur.split!("seconds", "nsecs")(secs, nansecs);
    timespec sleep_time = timespec(secs, nansecs);
    if (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &sleep_time, null))
        throw new Exception("Failed to call clock_nanosleep, and sleep as expected");
}

unittest 
{
    /* Test that it wakes at the correct time under normal use */
    auto time = MonoTime.currTime; 
    auto wake_time = time + 100.msecs;
    delayUntil(wake_time); 

    auto time_woken_at = MonoTime.currTime;
    assert(time_woken_at > time);
    assert(time_woken_at >= wake_time);
    assert(wake_time + 1.msecs > time_woken_at);
}

unittest 
{
    /* Test that it behaves as expected when given an empty time value */
    MonoTime startTime = MonoTime.currTime;

    MonoTime newtime = MonoTime();
    delayUntil(newtime);

    MonoTime endTime = MonoTime.currTime;

    assert(endTime > startTime);
    assert(endTime < startTime + 1.msecs);
}

unittest
{
    /* Test behaviour when given a time value that has already passed */
    MonoTime startTime = MonoTime.currTime;

    MonoTime newtime = MonoTime.currTime - 100.msecs;
    delayUntil(newtime);

    MonoTime endTime = MonoTime.currTime;

    assert(endTime > startTime);
    assert(endTime < startTime + 1.msecs);
}

unittest
{
    /* Test interrupting the clock_nanosleep call with a signal. This should
     * cause a return of EINTR, therefore throwing an exception that we can
     * catch */
    import core.sys.posix.signal;
    __gshared pthread_t myThread;
    void threadFunc()
    {
        Thread.sleep(100.msecs);
        pthread_kill(myThread, 36);
    }

    extern (C) @nogc void sighandler(int signum) nothrow
    {
    }

    new Thread(&threadFunc).start();
    signal(36, &sighandler);
    auto sleepTime = MonoTime.currTime + 10.seconds;
    myThread = Thread.getThis.id;
    int a = 0;
    try 
    {
        delayUntil(sleepTime);
    }
    catch (Exception ex)
    {
        a = 1;
        assert(ex.msg == "Failed to call clock_nanosleep, and sleep as expected");
    }
    assert (a == 1);
}








/** 
  * The following function provides a wrapper for POSIX system calls that set
  * the system scheduler. 
  * The ability to adjust the system scheduler is a requirement in a real-time
  * system, as fixed priority scheduling is commonly used. 
  * Regular 'fair' sharing algorithms are insufficient for a real-time system
  * as there is no guarantee on the ordering of thread execution. 
  * 
  * Params: 
  * int schedulerType = the time of scheduler to be set. 
  *     values can be: 
  *         SCHED_OTHER, 
  *         SCHED_BATCH, 
  *         SCHED_IDLE, 
  *     or for real time applications: 
  *         SCHED_FIFO, 
  *         SCHED_RR.
  * int schedulerPriority = the priority that the scheduler should run at.
  * 
  * Example: 
  * --- 
  * void main()
  * {
  *     setScheduler(SCHED_FIFO, 50);
  *     auto a = new Thread;
  *     ...
  * }
  * --- 
  * 
  * Note: 
  * Depending on the operating system that this is run on, changing the system
  * scheduler may require elevated priveledges in order to be run.
  * 
  * Note 2: 
  * The scedulers available depend on the operating system, and all may not be
  * present. 
  * 
  * Note 3: 
  * In order for this to effect all threads properly, this should be the first
  * thing run in the main function. If run after a thread has been created, the
  * thread will have incorrectly set PRIORITY_MAX and PRIORITY_MIN.
  *
  **/

public import core.sys.posix.sched : SCHED_FIFO, SCHED_OTHER, SCHED_RR;

void setScheduler(int schedulerType, int schedulerPriority)
{
    import core.sys.posix.sched : sched_param, sched_setscheduler; 
    sched_param sp = { sched_priority: schedulerPriority }; 
    int ret = sched_setscheduler(0, schedulerType, &sp); 
    if (ret == -1)
    {
        // Note: For this line to be covered during unittests, the application
        // must be run as an unpriveledged user. 
        throw new Exception("Unable to set the scheduler");
    }
}

unittest
{
    // Note: These lines may require a priveledged user to run them in order to
    // be covered during unittesting
    import core.sys.posix.sched : sched_getscheduler; 
    setScheduler(SCHED_FIFO, 50); 
    assert(sched_getscheduler(0) == SCHED_FIFO);
    setScheduler(SCHED_RR, 50); 
    assert(sched_getscheduler(0) == SCHED_RR);
}


// TODO - Add in my definition of real-time mutexes, and both methods of
// asynchronous transfer of control. 
