import core.sync.mutex; 

version(Posix) {
    import core.sys.posix.pthread; 
}

extern (C) nothrow
{
    enum
    {
        PTHREAD_PRIO_NONE, 
        PTHREAD_PRIO_INHERIT, 
        PTHREAD_PRIO_PROTECT
    }

    int pthread_mutex_getprioceiling(in pthread_mutex_t*, int*);                
    int pthread_mutex_setprioceiling(pthread_mutex_t*, int, int*);              
    int pthread_mutexattr_getprioceiling(in pthread_mutexattr_t*, int*);        
    int pthread_mutexattr_getprotocol(in pthread_mutexattr_t*, int*);           
    int pthread_mutexattr_setprioceiling(pthread_mutexattr_t*, int);            
    int pthread_mutexattr_setprotocol(pthread_mutexattr_t*, int); 
}

class MutexWithPriorityInheritance : Mutex 
{
    this() nothrow @trusted {
        version( Windows )
        {
            InitializeCriticalSection( &m_hndl );
        }
        else version( Posix )
        {
            pthread_mutexattr_t attr = void;

            if( pthread_mutexattr_init( &attr ) )
                throw new SyncError( "Unable to initialize mutex" );
            scope(exit) pthread_mutexattr_destroy( &attr );

            //if( pthread_mutexattr_settype( &attr, PTHREAD_MUTEX_RECURSIVE ) )
            //    throw new SyncError( "Unable to initialize mutex" );

            if (pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT))
                throw new SyncError("Unable to initialize prio inheritance"); 

            if( pthread_mutex_init( &m_hndl, &attr ) )
                throw new SyncError( "Unable to initialize mutex" );
        }
        m_proxy.link = this;
        this.__monitor = &m_proxy;
    }

    final @nogc override @trusted nothrow void lock(){
        if (pthread_mutex_lock(&m_hndl)){
            SyncError syncErr = cast(SyncError) cast(void*) typeid(SyncError).init;
            syncErr.msg = "Unable to lock mutex.";
            throw syncErr;
        }
    }

    final @nogc override @trusted nothrow void unlock(){
        if (pthread_mutex_unlock(&m_hndl)){
            SyncError syncErr = cast(SyncError) cast(void*) typeid(SyncError).init;
            syncErr.msg = "Unable to unlock mutex.";
            throw syncErr;
        }
    }

    //private: 
    version(Posix) {
        pthread_mutex_t m_hndl;
    }
    MonitorProxy m_proxy;
}

