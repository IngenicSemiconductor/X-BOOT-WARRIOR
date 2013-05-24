#ifndef _NANDSEMPHORE_H_
#define _NANDSEMPHORE_H_

/************* NandSemaphore **********/
typedef int NandSemaphore;
void InitSemaphore(NandSemaphore*sem,int val); //val 1 is unLock val 0 is Lock
void DeinitSemaphore(NandSemaphore* sem);
void Semaphore_wait(NandSemaphore* sem);
int Semaphore_waittimeout(NandSemaphore* sem,long jiffies); //timeout return < 0
void Semaphore_signal(NandSemaphore* sem);

/************** andMutex **************/
typedef int NandMutex;
void InitNandMutex(NandMutex *mutex);
void DeinitNandMutex(NandMutex *mutex);
void NandMutex_Lock(NandMutex *mutex);
void NandMutex_Unlock(NandMutex* mutex);
int NandMutex_TryLock(NandMutex *mutex);
#endif /* _NANDSEMPHORE_H_ */
