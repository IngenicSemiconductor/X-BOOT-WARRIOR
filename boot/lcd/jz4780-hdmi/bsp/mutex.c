/*
 * mutex.c
 *
 *  Created on: Jun 25, 2010
 *  Synopsys Inc.
 *  SG DWC PT02
 */

#include "mutex.h"
#include "../util/log.h"
#include "../util/error.h"
//#include <linux/mutex.h>

int mutex_Initialize(void* pHandle)
{
#if 0
	struct mutex *mutex = (struct mutex *)pHandle;
	mutex_init(mutex);
#endif
	return TRUE;
}

int mutex_Destruct(void* pHandle)
{
	/* do nothing */
	return TRUE;
}

int mutex_Lock(void* pHandle)
{
#if 0
	struct mutex *mutex = (struct mutex *)pHandle;
	mutex_lock(mutex);
#endif
	return TRUE;
}

int mutex_Unlock(void* pHandle)
{
#if 0
	struct mutex *mutex = (struct mutex *)pHandle;
	mutex_unlock(mutex);
#endif
	return TRUE;
}
