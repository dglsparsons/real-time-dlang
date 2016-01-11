
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
        
        if (auto err = pthread_setschedprio(m_thr, Thread.getThis.priority))
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
}

extern (C) void* run(void* arg) 
{
    import core.sys.posix.pthread; 

    Interruptible obj = cast(Interruptible)(cast(void*)arg);

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
