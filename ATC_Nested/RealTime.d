//module rt.realtime; 

import core.time : MonoTime;//, Duration; 
import core.thread : Thread; 

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
    import core.sys.linux.time; 
    import core.time : Duration, timespec; 
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
 *  Also: Testing on Arch Linux, it appears SCHED_BATCH and SCHED_IDLE are not
 *  present?
 */
public import core.sys.posix.sched : SCHED_FIFO, SCHED_OTHER, SCHED_RR; 

void setScheduler(int scheduler_type, int scheduler_priority)
{
    import core.sys.posix.sched : sched_param, sched_setscheduler; 
    sched_param sp = { sched_priority: scheduler_priority }; 
    int ret = sched_setscheduler(0, scheduler_type, &sp); 
    if (ret == -1) {
        throw new Exception("scheduler did not properly set");
    }
}

unittest 
{
    import core.sys.posix.sched : sched_getscheduler; 
    setScheduler(SCHED_FIFO, 50); 
    auto a = sched_getscheduler(0); 
    assert(a == SCHED_FIFO); 
    setScheduler(SCHED_RR, 50); 
    a = sched_getscheduler(0); 
    assert(a == SCHED_RR); 
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

import core.sync.mutex : Mutex, SyncError; 
class RTMutex : Mutex 
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
        int ceiling; 
        if(pthread_mutex_getprioceiling(&m_hndl, &ceiling))
            throw new SyncError("Unable to fetch the priority ceiling for the associated Mutex"); 
        return ceiling; 
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
        if(pthread_mutex_setprioceiling(&m_hndl, val, null))
            throw new SyncError("Unable to set the priority ceiling for the associated Mutex"); 
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


/**
 * Sets up the signal handler and sets up signals to be redirected to the
 * handler in order to allow asynchronous interrupts to be used within the 
 * system.
 * This is a necessary feature of real-time systems, in order to allow
 * asynchronously interruptable sections of code to be executed, and fail
 * through if the behaviour is either not as expected, or if an exetrnal change
 * in environment justifies a need for it. 
 *
 * Example: 
 * ---
 * void main()
 * {
 *     enableInterruptableSections; 
 *     auto a = new RTThread(&thread_function); 
 *     a.start; 
 *     Thread.sleep(1.seconds); 
 *     a.interrupt; 
 * }
 * ---
 */

void enableInterruptableSections()
{
    import core.sys.posix.signal: sigaction_t, sigemptyset, sigaction; 
    sigaction_t action; 
    action.sa_handler = &sig_handler; 
    sigemptyset(&action.sa_mask); 
    sigaction(36, &action, null); 
}

unittest
{
    import core.sys.posix.signal : raise; 
    enableInterruptableSections(); 
    raise(36); // Should do nothing
}


extern (C) @safe void sig_handler(int signum)
{
    auto curr_thread = RTThread.getSelf(); 
    foreach(interrupt; curr_thread.interruptableSections)
    {
        if(interrupt.toThrow && interrupt.interruptable)
        {
            throw interrupt.interrupt; 
        }
    }
}

/** 
 * This is a derived class, inheriting from Exception, and exists for the sole
 * purpose of communicating that an asynchronously interruptable task has been
 * interrupted. 
 * 
 * Example: 
 * --- 
 * void thread_function()
 * {
 *     RTThread self = to!RTThread(Thread.getThis()); 
 *     self.interruptable = true; 
 *     try 
 *     {
 *         while(true) { Thread.sleep(1.seconds); writeln("Hello"); }
 *     }
 *     catch (AsyncException ex) {}
 * }
 * 
 * void main()
 * {
 *     auto a = new RTThread(&thread_fuction); 
 *     a.start(); 
 *     Thread.sleep(1.seconds); 
 *     a.interrupt(); 
 * }
 * --- 
 */

class AsyncInterrupt : Error
{
    uint depth; 
    this(uint d)
    {
        super(null, null); 
        depth = d;
    }
}

/** 
 * This is an extension of the default thread class, providing additional
 * functionality for real time systems in the form of support for asynchronous
 * interruptions. 
 * This is a requirement for real time systems in order for asynchronous
 * transfer control. 
 * 
 * Params: 
 * void function() fn = passing in a reference to a function will cause the
 * thread to execute the function following a call to start(); 
 * 
 * Example: 
 * ---
 * void thread_function()
 * {
 *     writeln("Hello, World!"); 
 * }
 * 
 * void main()
 * {
 *     new RTThread(&thread_function).start(); 
 * }
 * --- 
 * 
 * Note: 
 * In order to successfully implement the RTThread complete with interrupts,
 * the druntime was modified to make m_addr protected. This enables RTThread's
 * interrupt function to access the m_addr for the underlying pthread_kill
 * call. Alternative solutions would include: A full custom implementation of
 * thread, or modifying the default thread function to also have a public bool
 * interruptable would enable the same end result. 
 */

class RTThread : Thread 
{
    InterruptableSection[] interruptableSections = []; 
    bool interruptable = false; 
    uint depth = 0; 

    this(void function() fn)
    {
        super(fn); 
    }
    this(void delegate() fn)
    {
        super(fn); 
    }

    /** 
     * Sends an asynchronous interrupt to the thread, if the thread contains
     * any sections that are flagged as ready to throw an interrupt, then an
     * AsyncInterruption Error will be thrown. 
     * 
     * Throws: 
     * Exception on failure to send a signal to the thread
     * 
     * Example: 
     * --- 
     * void main()
     * {
     *     auto a = new RTThread(&thread_function);
     *     a.start(); 
     *     Thread.sleep(1.seconds); 
     *     a.interrupt(); 
     * }
     * --- 
     */

    void interrupt()
    {
        import core.sys.posix.signal : pthread_kill; 
        if (pthread_kill(m_addr, 36))
            throw new Exception("Unable to signal the thread"); 
    }


    /** 
     * Gets the current RTThread that is executing. 
     * 
     * Example: 
     * --- 
     * auto a = RTThread.getSelf(); 
     * RTThread.interrupt(); 
     * --- 
     */

    static RTThread getSelf() @trusted
    {
        import std.conv : to; 
        return to!RTThread(Thread.getThis);
    }
}

unittest
{
    void thread_func()
    {
        RTThread b = RTThread.getSelf; 
        assert(a == b); 
    }
    __gshared RTThread a; 
    a = new RTThread(&thread_func);
    a.start; 
}

/** 
 * This class is a predefined existance of an asynchronously interruptable
 * section of code. 
 * This is useful to the programmer as it removes the requirement for manually
 * handling interruptable sections of code, instead providing a neat interface
 * that additionally enables interruptable sections to be nested. 
 * 
 * Params: 
 * void delegate() dg 
 * or
 * void function() fn
 * Passing in either of the above will initialise the interruptable section of
 * code, setting up any necessary handlers and Errors. On a call to start,
 * execution of the delegate, dg, or function fn will begin. 
 * 
 * Example: 
 * ---
 * void threadFunction()
 * {
 *     void interruptableCode()
 *     {
 *         while(true) { Thread.sleep(10.seconds); }
 *     }
 *
 *     enableInterruptableSections(); 
 *     new InterruptableSection(&interruptableCode).start; 
 * }
 * 
 * void main()
 * {
 *     auto a = new RTThread(&threadFunction); 
 *     a.start;
 *     Thread.sleep(1.seconds); 
 *     a.interruptableSections[$].toThrow = true;
 *     a.interrupt();
 * }
 * --- 
 */

class InterruptableSection
{
    bool toThrow = false; 
    AsyncInterrupt interrupt; 

    private bool m_interruptable = false; 

    private void function(InterruptableSection x) m_fn; 
    private void delegate(InterruptableSection x) m_dg; 
    private Call m_call; 
    private enum Call { NO, FN, DG }; 

    this(void function(InterruptableSection x) fn)
    {
        m_fn = fn; 
        m_call = Call.FN; 
    }
    this(void delegate(InterruptableSection x) fn)
    {
        m_dg = fn; 
        m_call = Call.DG; 
    }

    /** 
     * The interruptable property allows sections of code within the
     * Interruptable block to defer being interrupted until a later moment in
     * time. This is useful for constructors, synchronised sections, or for
     * custom control of when code is interruptable. 
     * When allowing a section to be interruptable, i.e setting this value to
     * true, then an AsyncInterrupt may immediately occur. 
     * 
     * Example: 
     * --- 
     * RTThread.getSelf.interruptableSections[$].interruptable = false; 
     * // Perform some noninterruptable code. 
     * RTThread.getSelf.interruptableSections[$].interruptable = true; 
     * --- 
     */

    @trusted @property bool interruptable()
    {
        return m_interruptable; 
    }
    @property void interruptable(bool newValue)
    {
        m_interruptable = newValue; 
        if (newValue)
        {
            RTThread.getSelf.interrupt(); 
        }
    }

    /** 
     * Execute the function passed into the constructor as an interruptable
     * section. 
     * 
     * Example: 
     * ---
     * void interruptableCode()
     * {
     *     // do something
     * }
     * 
     * auto a = new InterruptableSection(&interruptableCode); 
     * a.start(); 
     * ---
     */

    void start()
    {
        // Track the current Interruptable sections within the thread
        auto curr_thread = RTThread.getSelf;
        curr_thread.interruptableSections ~= this;
        scope(exit) curr_thread.interruptableSections = curr_thread.interruptableSections[0..$-1];
        interrupt = new AsyncInterrupt(curr_thread.depth); 

        curr_thread.depth += 1; 
        scope(exit) curr_thread.depth -= 1; 

        // execute the desired functionality
        try {
            interruptable = true;
            scope(exit) interruptable = false; 
            switch( m_call )
            {
                case Call.FN:
                    m_fn(this);
                    break;
                case Call.DG:
                    m_dg(this);
                    break;
                default:
                    break;
            }     
        }
        catch (AsyncInterrupt caughtex)
        {
            if (interrupt.depth != caughtex.depth)
                throw caughtex; 
        }
    }
}
