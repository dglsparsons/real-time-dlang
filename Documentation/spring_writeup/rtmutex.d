private class RTMutex : Object.Monitor
{
    ...
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
    ...
}
