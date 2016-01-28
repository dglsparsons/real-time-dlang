/**
  realtime.d is a set of functionality provided to aid the development of a 
  real-time system when using the D programming language. It provides support 
  for the following primitives: 
  - Ability to change the system scheduler to a priority based scheduler.
  - Monotonic clock, and ability to sleep a threads execution until an absolute
  time
  - Mutexes that provide the Priority inheritance and the Immediate Priority 
  Ceiling protocols
  - Two alternate implementations of Asynchronous Transfer of Control. One
  using threads and cancellation points, the other using Signals to insert an 
  exception into the context of a thread. 

  This module has been written by Douglas Parsons as part of an Undergraduate 
  Degree at the University of York, UK. 
 **/


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
















/* 
   Private enum is used for initialising RTMutex with either the priority ceiling 
   protocol, or the immediate priority ceiling protocol. This is passed in to the 
   RTMutex's constructor as an argument when creating either a new CeilingMutex 
   or InheritanceMutex.
 */

private enum {PROTOCOL_INHERIT = 1, PROTOCOL_CEILING };

/* 
   External imports required for the creation of RTMutex 
 */
version( Posix ) extern (C) nothrow
{
    private import core.sys.posix.sys.types; 
    enum 
    {
        PTHREAD_PRIO_NONE, 
        PTHREAD_PRIO_INHERIT, 
        PTHREAD_PRIO_PROTECT
    }

    int pthread_mutex_getprioceiling(in pthread_mutex_t*, int*);
    int pthread_mutex_setprioceiling(pthread_mutex_t*, int, int*);
    int pthread_mutexattr_getprioceiling(in pthread_mutexattr_t*, int*);
    int pthread_mutexattr_getprotocol(in pthread_mutexattr_t*, int*);
    int pthread_mutexattr_setprioceiling(pthread_mutexattr_t*, int);
    int pthread_mutexattr_setprotocol(pthread_mutexattr_t*, int);
}

/* 
   class RTMutex is a private class, used internally within InheritanceMutex and 
   CeilingMutex along with the alias this trick. 
   This class is similar to the druntime Mutex, providing features such as an 
   ability to add a Mutex to an object, and the ability to lock, testLock, and 
   unlock. 
   Additionally, an int, representing protcol may be passed into the constructor. 
   Defining whether the Mutex should implement the Priority Inheritance, or the 
   Priority Ceiling protocol.

 */
private class RTMutex : Object.Monitor
{
    private import core.sys.posix.pthread;
    private import core.sync.exception : SyncError;

    /* Initialiser
       protocol = the protocol that the Mutex should implement. see private enum 
       for the protocol types
       */
    this(int protocol) nothrow @trusted
    {
        pthread_mutexattr_t mutexAttr = void;

        if( pthread_mutexattr_init( &mutexAttr ) )
            throw new SyncError( "Unable to initialize mutex" );
        scope(exit) pthread_mutexattr_destroy( &mutexAttr );

        if( pthread_mutexattr_settype( &mutexAttr, PTHREAD_MUTEX_RECURSIVE ) )
            throw new SyncError( "Unable to initialize mutex" );

        if(protocol == PROTOCOL_CEILING)
        {
            if(pthread_mutexattr_setprotocol(&mutexAttr, PTHREAD_PRIO_PROTECT))
            {
                throw new SyncError("Unable to initialize Priority ceiling protocol"); 
            }
        }
        else if (protocol == PROTOCOL_INHERIT)
        {
            if(pthread_mutexattr_setprotocol(&mutexAttr, PTHREAD_PRIO_INHERIT))
                throw new SyncError("Unable to initialize Priority inheritance protocol"); 
        }

        if( pthread_mutex_init( &mutexID, &mutexAttr ) )
            throw new SyncError( "Unable to initialize mutex" );
        monProxy.link = this;
        this.__monitor = &monProxy;
    }


    /*
      Initialiser for creating a monitored object
     */
    this( Object obj , int protocol ) nothrow @trusted
        in
        {
            assert( obj.__monitor is null );
        }
    body
    {
        this(protocol);
        obj.__monitor = &monProxy;
    }


    /* 
       Destructor - releases any resources
       */
    ~this()
    {
        int rc = pthread_mutex_destroy( &mutexID );
        assert( !rc, "Unable to destroy mutex" );
        this.__monitor = null;
    }



    /**
     * If the mutex is not locked, then it is locked by the calling thread,
     * incementing its internal counter by one (it is a recursive mutex). 
     * Subsequent calls from the same thread will further increment the internal 
     * counter. 
     * A call to unlock() will decrement the counter if it is held by the
     * calling thread. 
     *
     */
    @trusted void lock() 
    {
        lock_nothrow();
    }

    // Internal Function
    final void lock_nothrow() nothrow @trusted @nogc
    {
        int returnedNumber = pthread_mutex_lock( &mutexID );
        if( returnedNumber )
        {
            SyncError syncErr = cast(SyncError) cast(void*) typeid(SyncError).init;
            syncErr.msg = "Unable to lock mutex.";
            throw syncErr;
        }
    }

    /**
      * If the mutex is locked, a call to unlock() will decrement its internal
      * counter by one. If the count becomes zero, it is fully released, and
      * able to be locked by other threads. 
     */
    @trusted void unlock()
    {
        unlock_nothrow();
    }

    // Internal Function
    final void unlock_nothrow() nothrow @trusted @nogc
    {
        int returnedNumber = pthread_mutex_unlock( &mutexID );
        if( returnedNumber )
        {
            SyncError syncErr = cast(SyncError) cast(void*) typeid(SyncError).init;
            syncErr.msg = "Unable to unlock mutex.";
            throw syncErr;
        }
    }

    /**
     * This function attempts to lock the mutex, immediately returning whether
     * the attempt was successful or not. 
     *
     * Returns:
     *  True if the calling thread was able to lock the mutex. Otherwise, false
     */
    bool tryLock()
    {
        return pthread_mutex_trylock( &mutexID ) == 0;
    }


    protected pthread_mutex_t mutexID;

    struct MonitorProxy
    {
        Object.Monitor link;
    }

    MonitorProxy monProxy;


    pthread_mutex_t* handleAddr()
    {
        return &mutexID;
    }
}

unittest
{
    /* This unittest is to check that RTMutex works properly when it is set 
       as a mutex on an object
     */
    import core.thread;
    __gshared int a = 0;

    class MyObject : Object
    {
        int count;
        this()
        {
            count = 0;
        }
        void increment()
        {
            count++;
        }
    }

    auto obj = new MyObject; 
    auto mut = new RTMutex(obj, PROTOCOL_INHERIT);
    auto numTries = 100;
    void testFn()
    {
        for (int i = 0; i < numTries; ++i)
        {
            synchronized(obj)
            {
                obj.increment;
            }
        }
    }


    auto group = new ThreadGroup;
    int numThreads = 10;
    for( int i = 0; i < numThreads; ++i )
        group.create( &testFn );

    group.joinAll();
    assert( obj.count == numThreads * numTries );
}

unittest
{
    /* This unittest is to determine that the RTMutex with the priority
     * inheritance protocol is functioning properly */
    import core.thread;
    auto mutex      = new RTMutex(PROTOCOL_INHERIT);
    int  numThreads = 10;
    int  numTries   = 1000;
    int  lockCount  = 0;

    void testFn()
    {
        for( int i = 0; i < numTries; ++i )
        {
            synchronized( mutex )
            {
                ++lockCount;
            }
        }
    }

    auto group = new ThreadGroup;

    for( int i = 0; i < numThreads; ++i )
        group.create( &testFn );

    group.joinAll();
    assert( lockCount == numThreads * numTries );
}



/**
  * CeilingMutex is a class, representing a Mutex that implements the immediate 
  * priority ceiling protocol. 
  * It is a requirement of a real-time system to implement the priority ceiling
  * protocol, in addition to the priority inheritance protocol. This provides a
  * bounded limit on the amount of blocking a high priority task may incur when
  * attempting to access a resource. 
  * Note that in order for this type of Mutex to correctly function, it should
  * also have its priority ceiling set using the ceiling property. 
  * 
  * Example: 
  * ---
  * auto a = new CeilingMutex(); 
  * a.priority = 50; 
  * synchronized ( a )
  * {
  *     // do something
  * }
  * --- 
  * 
  * Note: The implementation makes use of the alias this trick, to provide a
  * simplistic implementation. This has additional overhead for the garbage
  * collector however. 
  *
  **/
class CeilingMutex 
{
    private import core.sync.exception : SyncError;
    alias ceilingMutex this;
    RTMutex ceilingMutex;

    /** 
      * Initializes a new CeilingMutex
      * 
      **/
    this()
    {
        ceilingMutex = new RTMutex(PROTOCOL_CEILING);
        this.ceiling = 1;
    }

    /** 
      * The property, ceiling provides the value of the priority ceiling that
      * the protocol implements. When locking the mutex, a Threads priority is
      * effectively raised to that of the ceiling. This value should be the
      * highest priority of any Thread that accesses this resource. 
      * 
      * Example:
      * ---
      * auto a = new CeilingMutex; 
      * a.ceiling = 99; 
      * writeln("Ceiling is set to ", a.ceiling);
      * ---
      **/

    final @property int ceiling()
    {
        int ceiling; 
        if(pthread_mutex_getprioceiling(this.handleAddr, &ceiling))
            throw new SyncError("Unable to fetch the priority ceiling for the associated Mutex"); 
        return ceiling; 
    }

    final @property void ceiling(int val)
    {
        if(pthread_mutex_setprioceiling(this.handleAddr, val, null))
            throw new SyncError("Unable to set the priority ceiling for the associated Mutex"); 
    }
}







/**
  * InheritanceMutex is a class, representing a Mutex that implements the
  * priority inheritance protocol.
  * It is a requirement of a real-time system to implement the priority
  * inheritance protocol, in addition to the priority ceiling protocol. 
  * This provides a
  * bounded limit on the amount of blocking a high priority task may incur when
  * attempting to access a resource. 
  * 
  * Example: 
  * ---
  * auto a = new InheritanceMutex(); 
  * synchronized ( a )
  * {
  *     // do something
  * }
  * --- 
  * 
  * Note: The implementation makes use of the alias this trick, to provide a
  * simplistic implementation. However, this has additional overhead for the 
  * garbage collector due to the creation of a second managed object. 
  *
  **/
class InheritanceMutex
{
    alias inheritMutex this; 
    RTMutex inheritMutex; 
    this()
    {
        inheritMutex = new RTMutex(PROTOCOL_INHERIT);
    }
}

unittest 
{
    /* This unittest is to test the properties of the Ceiling Mutex in order to
     * confirm that they are properly being set 
     */
    auto a = new CeilingMutex();
    int prio = 50; 
    a.ceiling(prio); 
    assert(prio == a.ceiling); 
    int newPrio = 25; 
    a.ceiling(newPrio); 
    assert(prio != a.ceiling); 
    assert(newPrio == a.ceiling); 
}

unittest
{
    /* This unittest is to test that the CeilingMutex class functions properly.
     */
    import core.thread;
    auto mutex      = new CeilingMutex;
    int  numThreads = 10;
    int  numTries   = 1000;
    int  lockCount  = 0;
    void testFn()
    {
        for( int i = 0; i < numTries; ++i )
        {
            synchronized( mutex )
            {
                ++lockCount;
            }
        }
    }
    auto group = new ThreadGroup;
    for( int i = 0; i < numThreads; ++i )
        group.create( &testFn );
    group.joinAll();
    assert( lockCount == numThreads * numTries );
}

unittest
{
    /* This unittest is to test that the InheritanceMutex class functions properly.
     */
    import core.thread;
    auto mutex      = new InheritanceMutex;
    int  numThreads = 10;
    int  numTries   = 1000;
    int  lockCount  = 0;
    void testFn()
    {
        for( int i = 0; i < numTries; ++i )
        {
            synchronized( mutex )
            {
                ++lockCount;
            }
        }
    }
    auto group = new ThreadGroup;
    for( int i = 0; i < numThreads; ++i )
        group.create( &testFn );
    group.joinAll();
    assert( lockCount == numThreads * numTries );
}

unittest
{
    /* This unittest is to test the ability of tryLock to return immediately
     * and return true only if the mutex is successfully locked */
    import core.thread; 
    auto mutex = new InheritanceMutex;
    __gshared int i;
    void testFn()
    {
        Thread.sleep(100.msecs);
        auto b = mutex.tryLock(); 
        assert(!b);
    }
    new Thread(&testFn).start();
    auto a = mutex.inheritMutex.tryLock();
    if (a)
        i++; 
    thread_joinAll;
    mutex.unlock;
    assert(i == 1);
}

// TODO - add in Interruptible functionality
