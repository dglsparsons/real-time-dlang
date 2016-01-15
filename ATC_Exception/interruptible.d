
class Interruptible
{
    import core.sys.posix.pthread;
    private void function() m_fn;
    private pthread_t m_threadId; 

    this(void function() fn)
    {
        m_fn = fn; 
    }


    void start()
    {
        import core.thread; 
        m_threadId = Thread.getThis.id;
        try 
        {
            m_fn();
        } 
        catch (ATCInterrupt ex)
        {
            import std.stdio : writeln; 
            writeln("ATCException caught: ", ex.depth); 
        }
    }

    void interrupt()
    {
        import core.sys.posix.signal; 
        if (pthread_kill(m_threadId, 36))
            throw new Exception("Unable to signal the interruptible section");
    }
}

import core.exception;
class ATCInterrupt : Error
{
    int depth;
    this()
    {
        super(null, null);
        depth = 0;
    }
}

void enableInterruptableSections()
{
    import core.sys.posix.signal: sigaction_t, sigemptyset, sigaction; 
    sigaction_t action; 
    action.sa_handler = &sig_handler; 
    sigemptyset(&action.sa_mask);
    sigaction(36, &action, null); 
}

extern (C) @safe void sig_handler(int signum)
{
    import std.stdio;
    writeln("SIGNAL HANDLER");
}
