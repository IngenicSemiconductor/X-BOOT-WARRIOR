/*
 * Copyright (C) 2007 Ingenic Semiconductor Inc.
 * Author: Peter <jlwei@ingenic.cn>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <config.h>
#include <serial.h>
#include <debug.h>
#include <common.h>


#if defined(CONFIG_MSC_X_BOOT) || defined(CONFIG_MSC_SPL)
#ifdef CONFIG_JZ4760B

/*
 * External routines
 */
extern void flush_cache_all(void);
extern void init_sdram(void);
extern void init_pll(void);
extern void init_gpio(void);
extern void ddr_mem_init(int msel, int hl, int tsel, int arg);

#define u32 unsigned int
#define u16 unsigned short
#define u8 unsigned char
static int rca;
static int highcap = 0;

/*
 * GPIO definition
 */
#define MMC_IRQ_MASK()				\
do {						\
	REG_MSC_IMASK = 0xffff;			\
	REG_MSC_IREG = 0xffff;			\
} while (0)

static void mudelay(unsigned int usec)
{
    //unsigned int i = usec * (336000000 / 2000000);
	unsigned int i = usec  << 7;
    __asm__ __volatile__ (
        "\t.set noreorder\n"
        "1:\n\t"
        "bne\t%0, $0, 1b\n\t"
        "addi\t%0, %0, -1\n\t"
        ".set reorder\n"
        : "=r" (i)
        : "0" (i)
    );

}

static void sd_mdelay(int sdelay)
{
    mudelay(sdelay * 1000);	
}

/* Stop the MMC clock and wait while it happens */
static inline int jz_mmc_stop_clock(void)
{
	int timeout = 1000;
	int wait = 12; /* 1 us */ 

	REG_MSC_STRPCL = MSC_STRPCL_CLOCK_CONTROL_STOP;
	while (timeout && (REG_MSC_STAT & MSC_STAT_CLK_EN)) {
		timeout--;
		if (timeout == 0) {
			return -1;
		}
		wait = 12;
		while (wait--)
			;
	}
	return 0;
}

/* Start the MMC clock and operation */
static inline int jz_mmc_start_clock(void)
{
	REG_MSC_STRPCL = MSC_STRPCL_CLOCK_CONTROL_START | MSC_STRPCL_START_OP;
	return 0;
}

static u8 * mmc_cmd(u16 cmd, unsigned int arg, unsigned int cmdat, u16 rtype);
int mmc_block_readm(u32 src, u32 num, u8 *dst);
int  mmc_found(void);
int  mmc_init(void);
static int mmc_load(int uboot_size, u8 *dst);

static u8 * mmc_cmd(u16 cmd, unsigned int arg, unsigned int cmdat, u16 rtype)
{
	static u8 resp[20];
	u32 timeout = 0x3fffff;
	int words, i;

	jz_mmc_stop_clock();
	REG_MSC_CMD   = cmd;
	REG_MSC_ARG   = arg;
	REG_MSC_CMDAT = cmdat;

	REG_MSC_IMASK = ~MSC_IMASK_END_CMD_RES;
	jz_mmc_start_clock();

	while (timeout-- && !(REG_MSC_STAT & MSC_STAT_END_CMD_RES))
		;

	REG_MSC_IREG = MSC_IREG_END_CMD_RES;

	switch (rtype) {
	case MSC_CMDAT_RESPONSE_R1:
		case MSC_CMDAT_RESPONSE_R3:
			words = 3;
			break;
		case MSC_CMDAT_RESPONSE_R2:
			words = 8;
			break;
		default:
			return 0; 
	}

	for (i = words-1; i >= 0; i--) {
		u16 res_fifo = REG_MSC_RES;
		int offset = i << 1;
		
		resp[offset] = ((u8 *)&res_fifo)[0];
		resp[offset+1] = ((u8 *)&res_fifo)[1];
	}
	return resp;
}

int mmc_block_readm(u32 src, u32 num, u8 *dst)
{
	u8 *resp;
	u32 stat, timeout, data, cnt, wait, nob;

	resp = mmc_cmd(16, 0x200, 0x401, MSC_CMDAT_RESPONSE_R1);
	REG_MSC_BLKLEN = 0x200;
	REG_MSC_NOB = num / 512;

	if (highcap) 
		resp = mmc_cmd(18, src, 0x10409, MSC_CMDAT_RESPONSE_R1); // for sdhc card
	else
		resp = mmc_cmd(18, src * 512, 0x10409, MSC_CMDAT_RESPONSE_R1);
	nob  = num / 512;

	for (nob; nob >= 1; nob--) {
		timeout = 0x7ffffff;
		while (timeout) {
			timeout--;
			stat = REG_MSC_STAT;
		
			if (stat & MSC_STAT_TIME_OUT_READ) {
				serial_puts("\n TIME_OUT_READ\n\n");
				return -1;
			}
			else if (stat & MSC_STAT_CRC_READ_ERROR) {
				serial_puts("\n CRC_READ_ERROR\n\n");
				return -1;
			}
			else if (!(stat & MSC_STAT_DATA_FIFO_EMPTY)) {
				/* Ready to read data */
				break;
			}

			wait = 120;
			while (wait--)
				;
		}
		if (!timeout) {
			serial_puts("read timeout\n");
			return -1;
		}

		/* Read data from RXFIFO. It could be FULL or PARTIAL FULL */
		cnt = 128;
		while (cnt) {
			while (cnt && (REG_MSC_STAT & MSC_STAT_DATA_FIFO_EMPTY))
				;
			cnt --;
			data = REG_MSC_RXFIFO;
			{
				*dst++ = (u8)(data >> 0);
				*dst++ = (u8)(data >> 8);
				*dst++ = (u8)(data >> 16);
				*dst++ = (u8)(data >> 24);
			}
		}
	}
#if 0
	resp = mmc_cmd(12, 0, 0x41, MSC_CMDAT_RESPONSE_R1);
#endif
	while(!(REG_MSC_STAT & MSC_STAT_AUTO_CMD_DONE));
	jz_mmc_stop_clock();

	return 0;
}


/* init mmc/sd card we assume that the card is in the slot */
#ifdef CONFIG_MSC_TYPE_SD
static void sd_found(void)
{

	int retries, wait;
	u8 *resp;
	unsigned int cardaddr;
	serial_puts("SD card found!\n");

	resp = mmc_cmd(41, 0x40ff8000, 0x3, MSC_CMDAT_RESPONSE_R3);
	retries = 100;
	while (retries-- && resp && !(resp[4] & 0x80)) {
		resp = mmc_cmd(55, 0, 0x1, MSC_CMDAT_RESPONSE_R1);
		resp = mmc_cmd(41, 0x40ff8000, 0x3, MSC_CMDAT_RESPONSE_R3);
		sd_mdelay(10);
	}

	if (resp[4] & 0x80) 
		serial_puts("init ok\n");
	else 
		serial_puts("init fail\n");

	/* try to get card id */
	resp = mmc_cmd(2, 0, 0x2, MSC_CMDAT_RESPONSE_R2);
	resp = mmc_cmd(3, 0, 0x6, MSC_CMDAT_RESPONSE_R1);
	cardaddr = (resp[4] << 8) | resp[3]; 
	rca = cardaddr << 16;

	resp = mmc_cmd(9, rca, 0x2, MSC_CMDAT_RESPONSE_R2);
	highcap = (resp[14] & 0xc0) >> 6;
	resp = mmc_cmd(7, rca, 0x41, MSC_CMDAT_RESPONSE_R1);
	resp = mmc_cmd(55, rca, 0x1, MSC_CMDAT_RESPONSE_R1);
	resp = mmc_cmd(6, 0x2, 0x41, MSC_CMDAT_RESPONSE_R1);
	REG_MSC_CLKRT = 0;

}
#else//CONFIG_MSC_TYPE_MMC

int  mmc_found(void)
{

	int retries, wait;
	u8 *resp;

	serial_puts("MMC\n");
	resp = mmc_cmd(1, 0x40ff8000, 0x3, MSC_CMDAT_RESPONSE_R3);
	retries = 1000;
	while (retries-- && resp && !(resp[4] & 0x80)) {
		resp = mmc_cmd(1, 0x40300000, 0x3, MSC_CMDAT_RESPONSE_R3);
		sd_mdelay(10);
	}
		
	sd_mdelay(10);

	if ((resp[4] & 0x80 )== 0x80) 
		serial_puts(" ok@\n");
	else 
		serial_puts(" fail\n");
	
	if((resp[4] & 0x60 ) == 0x40)
		highcap = 1;
	else
		highcap =0;
	/* try to get card id */
	resp = mmc_cmd(2, 0, 0x2, MSC_CMDAT_RESPONSE_R2);
	resp = mmc_cmd(3, 0x10, 0x1, MSC_CMDAT_RESPONSE_R1);

	REG_MSC_CLKRT = 1;	/* 16/1 MHz */
	resp = mmc_cmd(7, 0x10, 0x1, MSC_CMDAT_RESPONSE_R1);
	resp = mmc_cmd(6, 0x3b70101, 0x441, MSC_CMDAT_RESPONSE_R1);
	while(!(REG_MSC_STAT & MSC_STAT_PRG_DONE));

	return 0;
}
#endif//CONFIG_MSC_TYPE_SD

int  mmc_init(void)
{
	int retries, wait;
	u8 *resp;

	__gpio_as_msc0_boot();
//	__gpio_as_msc();
	__msc_reset();

	MMC_IRQ_MASK();	
	__cpm_select_msc_clk(0,1);
	REG_MSC_CLKRT = 7;    //187k
	REG_MSC_RDTO = 0xffffffff;
	
	/* just for reading and writing, suddenly it was reset, and the power of sd card was not broken off */
	resp = mmc_cmd(12, 0, 0x41, MSC_CMDAT_RESPONSE_R1);

	/* reset */
	resp = mmc_cmd(0, 0, 0x80, 0);
	resp = mmc_cmd(8, 0x1aa, 0x1, MSC_CMDAT_RESPONSE_R1);
#ifdef CONFIG_MSC_TYPE_SD
	sd_found();
#else
	mmc_found();
#endif
	return 0;
}

/*
 * Load kernel image from MMC/SD into RAM
 */
static int mmc_load(int uboot_size, u8 *dst)
{
	dst = UNCACHE_ADDR(dst);
	
	mmc_init();
	mmc_block_readm(17, uboot_size, dst);

	return 0;
}

void spl_main(void)
{
/* 	REG_GPIO_PXFUNC(32*3+28); */
/* 	REG_GPIO_PXSELC(32*3+28); */
/* 	REG_GPIO_PXDIRS(32*3+28); */
/* 	REG_GPIO_PXDATC(32*3+28); */

/* 	__gpio_as_output(32*3+28); */
/* 	__gpio_enable_pull(32*3+28); */
/* 	__gpio_clear_pin(32*3+28); */

	void (*xboot)(void);
	int i;
	/*
	 * Init hardware
	 */
	 /*
	 * Initialize UART's clock
	 */
#if CFG_UART_BASE == UART0_BASE
	__cpm_start_uart0();
#elif CFG_UART_BASE == UART1_BASE
	__cpm_start_uart1();
#elif CFG_UART_BASE == UART2_BASE
	__cpm_start_uart2();
#else //CFG_UART_BASE == UART3_BASE
	__cpm_start_uart3();
#endif
	
	__cpm_start_mdma();
	__cpm_start_emc();
	__cpm_start_ddr();

	/* enable mdmac's clock */
//	REG_MDMAC_DMACKE = 0x3;                                                 
	REG_MDMAC_DMACKES = 0x3;

	init_gpio();

	// This function can avoid UART floating, but should not call if UART will be in high frequency.
	init_serial();
#ifdef OPT_LOCAL_DEBUG
	serial_puts_info("Serial is ok ...\n");
#endif

//	serial_puts("\n\nMSC Secondary Program Loader\n");

	init_pll();
	init_sdram();

#ifdef OPT_LOCAL_DEBUG
	serial_puts_info("Sdram initted ...\n");
#endif

	/*
	 * Load X-Boot image from NAND into RAM
	 */
	mmc_load(CFG_MSC_X_BOOT_SIZE, (unsigned char *)CFG_MSC_X_BOOT_DST);

	xboot = (void (*)(void))CFG_MSC_X_BOOT_START;

#ifdef OPT_LOCAL_DEBUG
	serial_puts("Starting X-Boot ...\n");
#endif

	/*
	 * Flush caches
	 */
	flush_cache_all();

	/*
	 * Jump to x-boot image
	 */
	char* kernel_addr = (char *)0x80100000;//CFG_MSC_X_BOOT_START;
//	kernel_addr = CFG_MSC_X_BOOT_START;
//	serial_puts_info(kernel_addr);

#ifdef OPT_LOCAL_DEBUG
	serial_puts("jump to x-boot\n");
#endif
//	serial_put_hex(xboot);
	(*xboot)();
}
#endif /* CONFIG_JZ4760B */
#endif
