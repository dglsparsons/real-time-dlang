alias self = Interruptible.getThis;

class Interruptible
{
    import core.sys.posix.pthread;
    private void function() m_fn;
    private pthread_t m_threadId; 
    public ATCInterrupt m_error; 

    static private Interruptible sm_this = null;
    shared static Interruptible toThrow;

    this(void function() fn)
    {
        m_fn = fn; 
        m_error = new ATCInterrupt(this); 
    }

    static Interruptible getThis()
    {
        return sm_this;
    }

    private ATCInterrupt m_caughtError;

    void start()
    {
        import core.thread; 
        m_threadId = Thread.getThis.id;
        auto previousInterruptible = sm_this;
        scope(exit) sm_this = previousInterruptible;
        sm_this = this; 
        try 
        {
            m_fn();
        } 
        catch (ATCInterrupt ex)
        {
            m_caughtError = ex;
        }
        finally 
        {
            foreach(int i, fn; cleanup_fns)
            {
                fn(cleanup_args[i]);
            }
            if (m_caughtError.owner != this)
            {
                throw m_caughtError;
            } else { import std.stdio; writeln("Error Caught"); }
        }
    }

    void interrupt()
    {
        import core.sys.posix.signal; 
        Interruptible.toThrow = cast(shared Interruptible)this;
        if (pthread_kill(m_threadId, 36))
            throw new Exception("Unable to signal the interruptible section");
    }

    private void function(void*)[] cleanup_fns;
    private void*[] cleanup_args;

    void* addCleanup(void function(void*) fn, void* arg)
    {
        cleanup_fns = fn ~ cleanup_fns;
        cleanup_args = arg ~ cleanup_args;
        auto value = (fn, arg);
        return value;
    }
}

struct Cleanup
{
    void function(void*) fn;
    void* arg;

    this(void function(void*) _fn, void* _arg)
    {
        fn = _fn; 
        arg = _arg;
    }
}

import core.exception;
class ATCInterrupt : Error
{
    Interruptible owner;
    this(Interruptible own)
    {
        super(null, null);
        owner = own;
    }
}

void enableInterruptibleSections()
{
    import core.sys.posix.signal: sigaction_t, sigemptyset, sigaction; 
    sigaction_t action; 
    action.sa_handler = &sig_handler; 
    sigemptyset(&action.sa_mask);
    sigaction(36, &action, null); 
}

extern (C) @safe void sig_handler(int signum)
{
    if ( !(Interruptible.sm_this is null) )
    {
        throw Interruptible.toThrow.m_error;
    }
    else 
    {
        import std.stdio;
        writeln("SIGNAL HANDLER DEFERRED?");
    }
}
