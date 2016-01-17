
class Interruptible
{
    import core.thread, 
           core.sys.posix.pthread, 
           core.sync.condition, 
           core.sync.mutex; 

    private void delegate() m_dg;
    private void function() m_fn;

    private Call m_call;
    private enum Call {NO, FN, DG};

    private pthread_t m_thr;

    private static pthread_t sm_thr; 
    private static Interruptible sm_this;

    Interruptible child;

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

        if (Interruptible.sm_thr != 0)
        {
            // this means we are inside an interruptible section already.
            // Then we need to set the parent Interruptibles child, allowing cancels
            // to propagate.
            Interruptible.getThis.child = this;
        }

        if (pthread_create(&m_thr, &attr, &run, cast(void*)this))
        {
            throw new Error("Unable to create thread"); 
        }

        auto a = sched_getscheduler(0);

        if (pthread_setschedprio(m_thr, getParentPriority))
        {
            throw new Error("Unable to correctly set thread priority"); 
        }


        pthread_join(m_thr, null); 
    }

    void interrupt()
    {
        pthread_cancel(m_thr); 
        if( !(child is null) )
        {
            child.interrupt(); 
        }
    }

    int getParentPriority()
    {
        if (Interruptible.sm_thr == 0) 
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

    static void setTid(pthread_t inr)
    {
        sm_thr = inr; 
    }

    static void setThis(Interruptible intr)
    {
        sm_this = intr;
    }

    static Interruptible getThis()
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

    Interruptible.setTid(obj.getThreadID); 
    Interruptible.setThis(obj);

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
