#include <pthread.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#define handle_error_en(en, msg) \
    do { errno = en; perror(msg); exit(EXIT_FAILURE); } while (0)

static int done = 0;
static int param; 
static int cleanup_pop_arg = 0;
static int cnt = 0;
static void cleanup_handler(void *arg); 
pthread_t newThread; 

static void * thread_start(void *arg)
{
    done = *(int*)arg; 
    time_t start, curr;
    pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL); 
    printf("Pthread started: %lu\n", pthread_self()); 

    pthread_cleanup_push(cleanup_handler, NULL);

    curr = start = time(NULL);

    while (!done) {
        pthread_testcancel();           /* A cancellation point */
        if (curr < time(NULL)) {
            curr = time(NULL);
            printf("cnt = %d\n", cnt);  /* A cancellation point */
            cnt++;
        }
    }

    pthread_cleanup_pop(cleanup_pop_arg);
    return NULL;
}

static void cleanup_handler(void *arg)
{
    printf("Pthread Cancelled: %lu\n", pthread_self()); 
    printf("Called clean-up handler\n");
    cnt = 0;
    int s; 
    param = 1; 
    //printf("Addr of thread_start: %lu", thread_start); 
    s = pthread_create(&newThread, NULL, thread_start, &param);
    printf("pthread_create value: %i\n", s); 
}



int main(int argc, char *argv[])
{
    pthread_t thr;
    int s;
    void *res;
    printf("main started: %lu\n", pthread_self()); 

    param = 0; 
    s = pthread_create(&thr, NULL, thread_start, &param);
    if (s != 0)
        handle_error_en(s, "pthread_create");

    sleep(2);           /* Allow new thread to run a while */

    if (argc > 1) {
        if (argc > 2)
            cleanup_pop_arg = atoi(argv[2]);
        done = 1;

    } else {
        printf("Canceling thread\n");
        s = pthread_cancel(thr);
        if (s != 0)
            handle_error_en(s, "pthread_cancel");
    }

    s = pthread_join(thr, &res);
    if (s != 0)
        handle_error_en(s, "pthread_join");

    if (res == PTHREAD_CANCELED)
        printf("Thread was canceled; cnt = %d\n", cnt);
    else
        printf("Thread terminated normally; cnt = %d\n", cnt);
    //exit(EXIT_SUCCESS);
    pthread_join(newThread, &res);
}
