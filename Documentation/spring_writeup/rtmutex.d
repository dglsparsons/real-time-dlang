private class RTMutex : Object.Monitor
{
    private import core.sys.posix.pthread;
    private import core.sync.exception : SyncError;

    /* Initialiser
       protocol = the protocol that the Mutex should implement. 
     */
    this(int protocol) nothrow @trusted
    {
        pthread_mutexattr_t mutexAttr = void;

        if( pthread_mutexattr_init( &mutexAttr ) )
            throw new SyncError("Unable to initialize mutex");
        scope(exit) pthread_mutexattr_destroy( &mutexAttr );

        if( pthread_mutexattr_settype( &mutexAttr, 
                                PTHREAD_MUTEX_RECURSIVE ) )
            throw new SyncError("Unable to initialize mutex");

        if(protocol == PROTOCOL_CEILING)
        {
            if(pthread_mutexattr_setprotocol(&mutexAttr, 
                                PTHREAD_PRIO_PROTECT))
            {
                throw new SyncError("Unable to initialize 
                                Priority ceiling protocol"); 
            }
        }
        else if (protocol == PROTOCOL_INHERIT)
        {
            if(pthread_mutexattr_setprotocol(&mutexAttr, 
                                PTHREAD_PRIO_INHERIT))
                throw new SyncError("Unable to initialize 
                            Priority inheritance protocol"); 
        }

        if( pthread_mutex_init( &mutexID, &mutexAttr ) )
            throw new SyncError("Unable to initialize mutex");
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
     * If the mutex is not locked, then it is locked by 
     * the calling thread, incrementing its internal 
     * counter by one (it is a recursive mutex). 
     * Subsequent calls from the same thread will further 
     * increment the internal counter. 
     * A call to unlock() will decrement the counter if 
     * it is held by the calling thread. 
     */
    @trusted void lock() 
    {
        lock_nothrow();
    }

    final void lock_nothrow() nothrow @trusted @nogc
    {
        int returnedNumber = 
                    pthread_mutex_lock(&mutexID);
        if( returnedNumber )
        {
            SyncError syncErr = cast(SyncError) 
                    cast(void*) typeid(SyncError).init;
            syncErr.msg = "Unable to lock mutex.";
            throw syncErr;
        }
    }

    /**
     * If the mutex is locked, a call to unlock() will 
     * decrement its internal counter by one. If the 
     * count becomes zero, it is fully released, and
     * able to be locked by other threads. 
     */
    @trusted void unlock()
    {
        unlock_nothrow();
    }

    // Internal Function
    final void unlock_nothrow() nothrow @trusted @nogc
    {
        int returnedNumber = pthread_mutex_unlock(&mutexID);
        if( returnedNumber )
        {
            SyncError syncErr = cast(SyncError) cast(void*) 
                                    typeid(SyncError).init;
            syncErr.msg = "Unable to unlock mutex.";
            throw syncErr;
        }
    }

    /**
     * This function attempts to lock the mutex, immediately 
     * returning whether the attempt was successful or not. 
     *
     * Returns:
     * true if the calling thread was able to lock the mutex. 
     * Otherwise, false
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
