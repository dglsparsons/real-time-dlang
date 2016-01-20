
private Interruptible currentInterruptible;

class Interruptible
{
    import core.sys.posix.pthread;
    private void function() m_fn;
    private pthread_t m_threadId; 
    public ATCInterrupt m_error; 

    this(void function() fn)
    {
        m_fn = fn; 
        m_error = new ATCInterrupt(0); 
    }


    void start()
    {
        import core.thread; 
        m_threadId = Thread.getThis.id;
        try 
        {
            auto previousInterruptible = currentInterruptible;
            scope(exit) currentInterruptible = previousInterruptible;
            currentInterruptible = this; 
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
    uint depth;
    this(uint d)
    {
        super(null, null);
        depth = d;
    }
}

void enableInterruptibleSections()
{
    import core.sys.posix.signal: sigaction_t, sigemptyset, sigaction; 
    sigaction_t action; 
    action.sa_handler = &sig_handler; 
    sigemptyset(&action.sa_mask);
    sigaction(36, &action, null); 
    currentInterruptible = null;
}

extern (C) @safe void sig_handler(int signum)
{
    if ( !(currentInterruptible is null) )
    {
        throw currentInterruptible.m_error;
    }
    else 
    {
        import std.stdio;
        writeln("SIGNAL HANDLER");
    }
}
