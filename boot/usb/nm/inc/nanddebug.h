#ifndef _NMDEBUG_H_
#define _NMDEBUG_H_

#include "os/NandDebug.h"

#define DEBUG 1

#define FUNC_DEBUG(x)				\
	enum {					\
		x##_INFO = 1,			\
		x##_DEBUG,			\
		x##_ERROR,			\
		x##_SYSINFO,			\
	}

FUNC_DEBUG(VNAND);
FUNC_DEBUG(SIGBLOCK);

FUNC_DEBUG(L2PCONVERT);
FUNC_DEBUG(CACHEDATA);
FUNC_DEBUG(CACHEMANAGER);
FUNC_DEBUG(CACHELIST);

FUNC_DEBUG(ZONEMANAGER);
FUNC_DEBUG(HASH);
FUNC_DEBUG(HASHNODE);
FUNC_DEBUG(ZONE);
FUNC_DEBUG(TASKMANAGER);
FUNC_DEBUG(PARTITION);
FUNC_DEBUG(RECYCLE);
FUNC_DEBUG(TIMER);
FUNC_DEBUG(JUNKZONE);
FUNC_DEBUG(MEMDEALOR);
FUNC_DEBUG(ZONEMEMORY);

#define ndprint(level,...)					\
	do {							\
		if (level >= nm_dbg_level) {			\
			__ndprint(__VA_ARGS__);			\
			if (level == 3)				\
				nd_dump_stack();		\
		}						\
	} while (0)

#endif /* _NMDEBUG_H_ */
