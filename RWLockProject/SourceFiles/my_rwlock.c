#include "my_rwlock.h"

void my_rwlock_init(my_rwlock_t* rw) {
    pthread_mutex_init(&rw->mutex, NULL);
    pthread_cond_init(&rw->read_cond, NULL);
    pthread_cond_init(&rw->write_cond, NULL);
    rw->readers_active = 0;
    rw->readers_waiting = 0;
    rw->writers_waiting = 0;
    rw->writer_active = 0;
}

void my_rwlock_destroy(my_rwlock_t* rw) {
    pthread_mutex_destroy(&rw->mutex);
    pthread_cond_destroy(&rw->read_cond);
    pthread_cond_destroy(&rw->write_cond);
}

void my_rwlock_rdlock(my_rwlock_t* rw) {
    pthread_mutex_lock(&rw->mutex);
    
    // Ждем, если есть активный писатель ИЛИ (важно!) если писатели ждут в очереди.
    // Это реализует приоритет писателей.
    while (rw->writer_active || rw->writers_waiting > 0) {
        rw->readers_waiting++;
        pthread_cond_wait(&rw->read_cond, &rw->mutex);
        rw->readers_waiting--;
    }
    
    rw->readers_active++;
    pthread_mutex_unlock(&rw->mutex);
}

void my_rwlock_wrlock(my_rwlock_t* rw) {
    pthread_mutex_lock(&rw->mutex);
    
    rw->writers_waiting++;
    
    // Писатель ждет, если есть другие писатели или активные читатели
    while (rw->writer_active || rw->readers_active > 0) {
        pthread_cond_wait(&rw->write_cond, &rw->mutex);
    }
    
    rw->writers_waiting--;
    rw->writer_active = 1;
    
    pthread_mutex_unlock(&rw->mutex);
}

void my_rwlock_unlock(my_rwlock_t* rw) {
    pthread_mutex_lock(&rw->mutex);
    
    if (rw->writer_active) {
        // Разблокирует писатель
        rw->writer_active = 0;
        
        // Если есть ждущие писатели - будим одного из них
        if (rw->writers_waiting > 0) {
            pthread_cond_signal(&rw->write_cond);
        } else {
            // Иначе будим всех читателей
            pthread_cond_broadcast(&rw->read_cond);
        }
    } else {
        // Разблокирует читатель
        rw->readers_active--;
        
        // Если читателей не осталось и есть ждущий писатель - будим его
        if (rw->readers_active == 0 && rw->writers_waiting > 0) {
            pthread_cond_signal(&rw->write_cond);
        }
    }
    
    pthread_mutex_unlock(&rw->mutex);
}