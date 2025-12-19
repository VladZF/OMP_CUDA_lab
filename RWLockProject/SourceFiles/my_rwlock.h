#ifndef MY_RWLOCK_H
#define MY_RWLOCK_H

#include <pthread.h>

typedef struct {
    // 1. Мьютекс
    pthread_mutex_t mutex;
    
    // 2. Две условные переменные
    pthread_cond_t read_cond;  // Для читателей
    pthread_cond_t write_cond; // Для писателей
    
    // 3. Счетчик читателей (сколько потоков в данный момент читают)
    int readers_active;
    
    // 4. Счетчик количества потоков, ожидающих получения блокировки на чтение
    int readers_waiting;
    
    // 5. Счетчик количества потоков, ожидающих получения блокировки на запись
    int writers_waiting;
    
    // 6. Флаг, показывающий, получил ли блокировку хотя бы один писатель
    int writer_active;
} my_rwlock_t;

void my_rwlock_init(my_rwlock_t* rw);
void my_rwlock_destroy(my_rwlock_t* rw);
void my_rwlock_rdlock(my_rwlock_t* rw);
void my_rwlock_wrlock(my_rwlock_t* rw);
void my_rwlock_unlock(my_rwlock_t* rw);

#endif