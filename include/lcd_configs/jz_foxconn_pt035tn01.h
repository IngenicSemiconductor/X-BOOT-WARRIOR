
#ifndef __JZ__FOXCONN_PT035TN01_H__
#define __JZ__FOXCONN_PT035TN01_H__
#include <config.h>
#include <common.h>
//extern void mdelay(unsigned msecs);
//extern void udelay(unsigned usecs);

#if defined(CONFIG_ANDROID_LCD_FOXCONN_PT035TN01) /* board FUWA */
#define MODE 0xcd 		/* 24bit parellel RGB */
#endif
#if defined(CONFIG_ANDROID_LCD_INNOLUX_PT035TN01_SERIAL)
#define MODE 0xc9		/* 8bit serial RGB */
#endif

#define __spi_write_reg1(reg, val) \
	do { \
		unsigned char no;\
		unsigned short value;\
		unsigned char a=0;\
		unsigned char b=0;\
		a=reg;\
		b=val;\
		__gpio_as_output(SPEN);\
		__gpio_as_output(SPCK);\
		__gpio_as_output(SPDA);\
		__gpio_set_pin(SPEN);\
		__gpio_set_pin(SPCK);\
		__gpio_clear_pin(SPDA);\
		__gpio_clear_pin(SPEN);\
		udelay(25);\
		value=((a<<8)|(b&0xFF));\
		for(no=0;no<16;no++)\
		{\
			__gpio_clear_pin(SPCK);\
			if((value&0x8000)==0x8000)\
			__gpio_set_pin(SPDA);\
			else\
			__gpio_clear_pin(SPDA);\
			udelay(25);\
			__gpio_set_pin(SPCK);\
			value=(value<<1); \
			udelay(25);\
		 }\
		__gpio_set_pin(SPEN);\
		udelay(100);\
	} while (0)

	#define __spi_write_reg(reg, val) \
	do {\
		__spi_write_reg1((reg<<2|2), val); \
		udelay(100); \
	}while(0)

	#define __lcd_special_pin_init() \
	do { \
		__gpio_as_output(LCD_RET);\
		__gpio_clear_pin(LCD_RET);\
		udelay(150000);\
		__gpio_set_pin(LCD_RET);\
	} while (0)

	#define __lcd_special_on() \
	do { \
		__gpio_as_output(LCD_RET);\
		udelay(50);\
		__gpio_clear_pin(LCD_RET);\
		udelay(150000);\
		__gpio_set_pin(LCD_RET);\
		udelay(10000);\
		__spi_write_reg(0x00, 0x03); \
		__spi_write_reg(0x01, 0x40); \
		__spi_write_reg(0x02, 0x11); \
		__spi_write_reg(0x03, MODE); /* mode */ \
		__spi_write_reg(0x04, 0x32); \
		__spi_write_reg(0x05, 0x0e); \
		__spi_write_reg(0x07, 0x03); \
		__spi_write_reg(0x08, 0x08); \
		__spi_write_reg(0x09, 0x32); \
		__spi_write_reg(0x0A, 0x88); \
		__spi_write_reg(0x0B, 0xc6); \
		__spi_write_reg(0x0C, 0x20); \
		__spi_write_reg(0x0D, 0x20); \
	} while (0)	//reg 0x0a is control the display direction:DB0->horizontal level DB1->vertical level

/*		__spi_write_reg(0x02, 0x03); \
		__spi_write_reg(0x06, 0x40); \
		__spi_write_reg(0x0a, 0x11); \
		__spi_write_reg(0x0e, 0xcd); \
		__spi_write_reg(0x12, 0x32); \
		__spi_write_reg(0x16, 0x0e); \
		__spi_write_reg(0x1e, 0x03); \
		__spi_write_reg(0x22, 0x08); \
		__spi_write_reg(0x26, 0x40); \
		__spi_write_reg(0x2a, 0x88); \
		__spi_write_reg(0x2e, 0x88); \
		__spi_write_reg(0x32, 0x20); \
		__spi_write_reg(0x36, 0x20); \
*/
//	} while (0)	//reg 0x0a is control the display direction:DB0->horizontal level DB1->vertical level

	#define __lcd_special_off() \
	do { \
		__spi_write_reg(0x00, 0x03); \
	} while (0)

#endif	/* CONFIG_JZ4760_LCD_FOXCONN_PT035TN01 or CONFIG_JZ4760_LCD_INNOLUX_PT035TN01_SERIAL */
