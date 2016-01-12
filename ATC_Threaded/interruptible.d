
class Interruptible
{
    import core.thread, 
           core.sys.posix.pthread, 
           core.sync.condition, 
           core.sync.mutex; 

    void delegate() m_dg;
    void function() m_fn;

    private Call m_call;
    private enum Call {NO, FN, DG};

    private pthread_t m_thr;

    static pthread_t sm_this; 

    this (void delegate() dg)
    {
        m_dg = dg; 
        m_call = Call.DG;
    }

    this (void function() fn)
    {
        m_fn = fn; 
        m_call = Call.FN; 
    }

    void start() 
    {
        pthread_attr_t attr; 
        if(pthread_attr_init(&attr))
        {
            throw new Error("Unable to initialise thread attributes"); 
        }

        if (pthread_create(&m_thr, &attr, &run, cast(void*)this))
        {
            throw new Error("Unable to create thread"); 
        }

        auto a = sched_getscheduler(0);

        import std.stdio; 
        writeln("sched_getscheduler(0): ", a); 
        writeln("priority: ");//, //Thread.getThis.priority()); 

        if (pthread_setschedprio(m_thr, getParentPriority))
        {
            throw new Error("Unable to correctly set thread priority"); 
        }

        pthread_join(m_thr, null); 
    }

    void interrupt()
    {
        int policy;
        sched_param param; 
        if (auto err = pthread_getschedparam(m_thr, &policy, &param))
        {
            throw new Error("NOOOO"); 
        }

        import std.stdio; 
        writeln("priority: ", param.sched_priority); 
        pthread_cancel(m_thr); 
    }

    int getParentPriority()
    {
        if (Interruptible.sm_this == 0) 
        {
            // Then we need the parent thread. 
            return Thread.getThis.priority;
        }
        else 
        {
            pthread_t parent_m_addr = pthread_self();
            // We need to get the parent pthread
            int         policy;
            sched_param param;
            if (auto err = pthread_getschedparam(parent_m_addr, &policy, &param))
            {
                //if (!atomicLoad(m_isRunning)) return PRIORITY_DEFAULT;
                throw new ThreadException("Unable to get thread priority");
            }
            return param.sched_priority;
        }
    }


    static void setThis(pthread_t inr)
    {
        sm_this = inr; 
    }

    static pthread_t getThis()
    {
        return sm_this; 
    }

    pthread_t getThreadID()
    {
        return m_thr;
    }
}

extern (C) void* run(void* arg) 
{
    import core.sys.posix.pthread; 

    Interruptible obj = cast(Interruptible)(cast(void*)arg);

    Interruptible.setThis(obj.getThreadID); 

    int oldtype; 
    pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, &oldtype); 

    if (obj.m_call == obj.Call.FN)
    {
        obj.m_fn(); 
    }
    else if (obj.m_call == obj.Call.DG)
    {
        obj.m_dg(); 
    }
    return null; 
}
