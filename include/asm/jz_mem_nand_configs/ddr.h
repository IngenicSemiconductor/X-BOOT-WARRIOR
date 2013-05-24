#define MAX(tck, time)								\
({										\
	unsigned long value, temp;						\
	value = (tck * ps > time) ? (tck * ps) : time;				\
	value = (value % 1000 == 0) ? (value / 1000) : (value / 1000 + 1);	\
	value;									\
})
