class Interruptible
{
    import core.thread; 
    import core.sys.posix.pthread; 
    import std.stdio; 

    void delegate() m_dg; 
    void function() m_fn; 
    private Call m_call; 
    private enum Call {NO, FN, DG}; 
    private pthread_t m_thr; 

    static Interruptible sm_this; 


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
    }

    void interrupt()
    {
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
