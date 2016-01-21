alias self = Interruptible.getThis;

import core.sys.posix.signal;

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
            foreach(_clean; cleanup_fns)
            {
                _clean.fn(_clean.arg);
            }
            if (m_caughtError.owner != this)
            {
                throw m_caughtError;
            } 
        }
    }

    void interrupt()
    {
        import core.sys.posix.signal; 
        Interruptible.toThrow = cast(shared Interruptible)this;
        if (pthread_kill(m_threadId, 36))
            throw new Exception("Unable to signal the interruptible section");
    }

    private Cleanup[] cleanup_fns;

    Cleanup addCleanup(void function(void*) fn, void* arg)
    {
        Cleanup __clean = Cleanup(fn, arg); 
        cleanup_fns = __clean ~ cleanup_fns;
        return __clean;
    }

    void removeCleanup(Cleanup cleanup)
    {
        if (cleanup_fns.length == 0) 
        {
            throw new Exception("Unable to remove");
        }
        foreach(int i, cln; cleanup_fns)
        {
            if (cleanup.fn == cln.fn)
            {
                cleanup_fns = cleanup_fns[0..i]; //~ cleanup_fns[i+1..$];
            }
        }
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

private immutable sigset_t __sigset_clear = sigset_t([34359738368, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

extern (C) /*@safe*/ void sig_handler(int signum)
{
    // since we are exiting on an exception, we need to reenable the signal
    // before throwing the exception. 
    scope(exit) sigprocmask(SIG_UNBLOCK, &__sigset_clear, null);

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
