#########################################################################
#
# Makefile for XBoot.
#
# Copyright (C) 2005 - 2010  Ingenic Semiconductor Corp.
#
#########################################################################

SUBDIRS = spl boot

#########################################################################

TOPDIR	:= $(shell /bin/pwd)
export TOPDIR

obj :=
src :=
export obj src

CROSS_COMPILE = mips-linux-gnu-
export CROSS_COMPILE

#########################################################################

# load other configuration
ifeq ($(TOPDIR)/include/config.mk,$(wildcard $(TOPDIR)/include/config.mk))
-include $(TOPDIR)/include/config.mk
endif

#########################################################################

ifeq ($(CONFIG_JZ4750),y)
CPU_TYPE = JZ4750
endif

ifeq ($(CONFIG_JZ4750L),y)
CPU_TYPE = JZ4750L
endif

ifeq ($(CONFIG_JZ4760),y)
CPU_TYPE = JZ4760
endif

ifeq ($(CONFIG_JZ4760B),y)
CPU_TYPE = JZ4760B
endif

ifeq ($(CONFIG_JZ4760B),y)
CPU_TYPE = JZ4770
endif

ifeq ($(CONFIG_JZ4780),y)
CPU_TYPE = JZ4780
endif

ifeq ($(CONFIG_JZ4775),y)
CPU_TYPE = JZ4775
endif

export CPU_TYPE

#########################################################################
#########################################################################

ifeq ($(CONFIG_NAND_X_BOOT),y)
NAND_SPL = nand-spl.bin
SPL_LOAD_ADDR = 0xf4000800
BOOTTYPE = nand
ALL = x-boot-nand.bin
endif

ifeq ($(CONFIG_MSC_X_BOOT),y)
MSC_SPL = msc-spl.bin

ifneq ($(CONFIG_NOR_SPL),y)
SPL_LOAD_ADDR = 0xf4000a00
else
SPL_LOAD_ADDR = 0xBA000000
endif
BOOTTYPE = msc
ALL = mbr-xboot.bin
endif

export BOOTTYPE SPL_LOAD_ADDR X_BOOT_LOAD_ADDR

#########################################################################
#########################################################################

ifeq ($(CONFIG_JZ4760_PT701_8),y)
BOARDDIR = pt701_8
endif

export BOARDDIR

#########################################################################
#########################################################################

#X_BOOT = x-boot.bin

MAKE := make

ifeq ($(CONFIG_THREE_STAGE),y)
X_BOOT2 = x-boot2.bin
X_BOOT3 = x-boot3.bin
MBR_XBOOT_DEPEND =
ALL += pack_logo
else
X_BOOT2 = x-boot3.bin
X_BOOT3 =
MBR_XBOOT_DEPEND = pack_logo
endif

ifeq ($(CONFIG_RSA_VERIFY),y)
MBR_XBOOT_DEPEND += pack_public_key
endif

.PHONY: $(ALL) $(MSC_SPL) $(NAND_SPL) pack_public_key pack_logo x-boot2.bin x-boot3.bin cyrpto_kit digi_sign mkxbootimg


all:		$(ALL)

$(X_BOOT2) : $(X_BOOT3)

crypto_kit:
		make -C boot mkxbootimg
		make -C boot pack
		make -C boot/tools/crypt/
		cp boot/tools/crypt/sign_boot crypto
		cp boot/tools/crypt/sign_kernel crypto
		cp boot/mkxbootimg crypto
		cp boot/pack crypto

digi_sign:
		cp mbr-xboot.bin crypto
		cp x-boot3.bin crypto
		cd crypto ; ./sign_boot_and_pack.sh

x-boot2.bin:
		X_BOOT_LOAD_ADDR=0x80100000 TARGET=second $(MAKE) -C boot x-boot.bin
		cp boot/x-boot.bin x-boot2.bin

x-boot3.bin:
		X_BOOT_LOAD_ADDR=0x80300000 TARGET=third $(MAKE) -C boot x-boot.bin
		cp boot/x-boot.bin x-boot3.bin

mkxbootimg:
		make -C boot mkxbootimg

pack_logo: x-boot3.bin mkxbootimg
		./boot/mkxbootimg --image boot/logo/$(shell sed -ne "s/.* \(.*\.rle\)/\1/p" boot/mklogo.sh) --addto $< -o $< --type 6
		./boot/mkxbootimg --image boot/logo/usb_online.rle --addto $< -o $< --type 7
		./boot/mkxbootimg --image boot/logo/usb_offline.rle --addto $< -o $< --type 8
		./boot/mkxbootimg --image boot/logo/recovery_mode.rle --addto $< -o $< --type 9

pack_public_key: $(X_BOOT2) mkxbootimg
		./boot/mkxbootimg --image boot/_mklogo.sh --addto $< -o $< --type 5

$(NAND_SPL):
		$(MAKE) -C spl $@

x-boot-nand.bin: $(NAND_SPL) $(MBR_XBOOT_DEPEND)
		$(MAKE) -C spl pad
ifeq ($(CONFIG_SECURITY_ENABLE),y)
		./tools/security/signatures_bootloader $(X_BOOT2) $(CONFIG_NAND_PAGESIZE) 6
		cat spl/nand-spl-pad.bin $(X_BOOT2).sig > x-boot-nand.bin
		./tools/security/signatures_spl x-boot-nand.bin 0 6
else
		cat spl/nand-spl-pad.bin $(X_BOOT2) > x-boot-nand.bin
endif

$(MSC_SPL):
		$(MAKE) -C spl $@

mbr-xboot.bin:	$(MSC_SPL) MBR $(MBR_XBOOT_DEPEND)
		$(MAKE) -C spl pad
		cat spl/msc-spl-pad.bin $(X_BOOT2) > x-boot-msc.bin
		cat mbr.bin x-boot-msc.bin > mbr-xboot.bin

MBR:
		gcc  spl/tools/mbr_creater/mbr_creater.c -o spl/tools/mbr_creater/mbr_creater -I$(TOPDIR) -I$(TOPDIR)/include
		spl/tools/mbr_creater/mbr_creater mbr.bin

$(LIBS):
		$(MAKE) -C $(dir $(subst $(obj),,$@))

PLL_CAL:
		gcc spl/tools/pll_calc/pll.c -o spl/tools/pll_calc/pllcalc -lm

#########################################################################

unconfig:
	@rm -f $(obj)include/config.h
	@rm -f $(obj)boot/mklogo.sh
	@echo "#!/bin/sh" > boot/mklogo.sh
	@chmod 777 boot/mklogo.sh
	@chmod 777 boot/_mklogo.sh
	@rm -rf ${PWD}/spl/common/jz_serial.c
	@rm -rf ${PWD}/spl/common/cpu.c
	@rm -rf ${PWD}/spl/common/debug.c
	@rm -rf ${PWD}/spl/common/common.c
	@rm -rf spl/tools/mbr_creater/mbr_creater
	@rm -rf spl/tools/mbr_creater/mbr.h
	@rm -rf spl/tools/pll_calc/pllcalc
	@sed -i "s/#define CONFIG_SERIAL_DISABLE 1/#define CONFIG_SERIAL_DISABLE 0/" include/serial.h

serial_disable_config:
	@sed -i "s/#define CONFIG_SERIAL_DISABLE 0/#define CONFIG_SERIAL_DISABLE 1/" include/serial.h
	@echo "CONFIG_SERIAL_DISABLE = y" >> include/config.mk

security_enable_config:
	@echo "#define CONFIG_SECURITY_ENABLE" >> include/config.h
	@echo "CONFIG_SECURITY_ENABLE = y" >> include/config.mk
#########################################################################
#########################################################################
test_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_TEST 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 test BOARD"
	@./mkconfig jz4780 test
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_TEST = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "CONFIG_NOR_SPL = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c


printer_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_PRINTER 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define NO_CHARGE_DETE" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 printer BOARD"
	@./mkconfig jz4780 printer 
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_PRINTER = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh printer_800_480.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
printer_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_PRINTER 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define NO_CHARGE_DETE" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile msc boot image for soc jz4780 printer BOARD"
	@./mkconfig jz4780 printer msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_PRINTER = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
urboard_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
#	@echo "#define CONFIG_LCD_KR070LA0S_270 1" >> include/config.h
#	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_URBOARD 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
#	@echo "#define NO_CHARGE_DETE" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
#	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
#	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
#	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
#	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "#define CONFIG_RELEASE_VERSION 0" >>include/config.h
	@echo "#define CONFIG_PRODUCT_NAME \"urboard\"" >>include/config.h
	@echo "Compile nand boot image for soc jz4780 urboard BOARD"
	@./mkconfig jz4780 urboard msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_URBOARD = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

ebook_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR070LA0S_270 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_EBOOK 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define NO_CHARGE_DETE" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "#define CONFIG_RELEASE_VERSION 0" >>include/config.h
	@echo "#define CONFIG_PRODUCT_NAME \"ebook\"" >>include/config.h
	@echo "Compile nand boot image for soc jz4780 ebook BOARD"
	@./mkconfig jz4780 ebook msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_EBOOK = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

warrior_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR070LA0S_270 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_WARRIOR 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define NO_CHARGE_DETE" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "#define CONFIG_RELEASE_VERSION 0" >>include/config.h
	@echo "#define CONFIG_PRODUCT_NAME \"warrior\"" >>include/config.h
	@echo "Compile nand boot image for soc jz4780 warrior BOARD"
	@./mkconfig jz4780 warrior msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_WARRIOR = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

warrior_release_config: unconfig warrior_nand_config
	@sed -i -r "s/CONFIG_RELEASE_VERSION 0/CONFIG_RELEASE_VERSION 1/" include/config.h

warrior_nand_se_config: unconfig warrior_nand_config security_enable_config serial_disable_config
	@echo "CONFIG_NAND_PAGESIZE = 4096" >> include/config.mk

grus_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KD50G2_40NM_A2 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_GRUS 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 grus BOARD"
	@./mkconfig jz4780 grus msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_GRUS = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

grus_nand_v101_config: unconfig grus_nand_config
	@sed -i -r "s/CONFIG_ACT8600/CONFIG_RICOH618/" include/config.h
	@sed -i -r "s/CONFIG_ACT8600/CONFIG_RICOH618/" include/config.mk


grus_msc_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KD50G2_40NM_A2 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_GRUS 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC0_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 grus BOARD"
	@./mkconfig jz4780 grus msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_GRUS = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

grus_msc1_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KD50G2_40NM_A2 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_GRUS 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 grus BOARD"
	@./mkconfig jz4780 grus msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_GRUS = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

test_msc_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_TEST 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_SD" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 test BOARD"
	@./mkconfig jz4780 test msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_TEST = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "CONFIG_NOR_SPL = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c



hdmi_80_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
#	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_HDMI_80 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC0 1" >> include/config.h
	@echo "#define CONFIG_ANDROID_LCD_HDMI_DEFAULT 1" >> include/config.h
	@echo "#define CONFIG_FORCE_RESOLUTION 4" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
#	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 hdmi_80 BOARD"
	@./mkconfig jz4780 hdmi_80 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_HDMI_80 = y" >> include/config.mk
	@echo "CONFIG_HDMI_JZ4780 = y" >> include/config.mk
#	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

m80_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_HSD101PWW1 1" >> include/config.h
#	@echo "#define CONFIG_LCD_LP101WX1_SLN2 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_M80 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 m80 BOARD"
	@./mkconfig jz4780 m80 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_M80 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh hdmi_1280_720.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

m80_tsd_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_M80 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TSD (MSC0) boot image for soc jz4780 m80 BOARD"
	@./mkconfig jz4780 m80 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_M80 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

m80_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_HSD101PWW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_M80 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 m80 BOARD"
	@./mkconfig jz4780 m80 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_M80 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh hdmi_1280_720.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

ji8070a_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_JI8070A 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 ji8070a BOARD"
	@./mkconfig jz4780 ji8070a msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_JI8070A = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

zpad80_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_ZPAD80 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 ji8070a BOARD"
	@./mkconfig jz4780 zpad80 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_ZPAD80 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

ji8070a_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_JI8070A 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 ji8070a BOARD"
	@./mkconfig jz4780 ji8070a msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_JI8070A = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

zpad80_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_ZPAD80 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 ji8070a BOARD"
	@./mkconfig jz4780 zpad80 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_ZPAD80 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c


ji8070b_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_HHX070ML208CP21 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_JI8070B 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 ji8070b BOARD"
	@./mkconfig jz4780 ji8070b msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_JI8070B = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
ji8070b_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_HHX070ML208CP21 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_JI8070B 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 ji8070b BOARD"
	@./mkconfig jz4780 ji8070b msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_JI8070B = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

q8_nand_for_fighter_config: unconfig
	@echo "#define CONFIG_BOOT_ZIMAGE_KERNEL" > include/config.h
	@echo "#define CONFIG_NAND_X_BOOT" >> include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_Q8 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 q8 BOARD"
	@./mkconfig jz4780 q8 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_Q8 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

q8a_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_Q8 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 q8 BOARD"
	@./mkconfig jz4780 q8 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_Q8 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
q8b_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_HHX070ML208CP21 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_Q8 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 q8 BOARD"
	@./mkconfig jz4780 q8 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_Q8 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
q8a_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_HSD070IDW1 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_Q8 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 ji8070a BOARD"
	@./mkconfig jz4780 q8 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_Q8 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
q8b_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_HHX070ML208CP21 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_Q8 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 ji8070a BOARD"
	@./mkconfig jz4780 q8 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_Q8 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c
m80701_tsd_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_M80701 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TSD (MSC0) boot image for soc jz4780 m80701 BOARD"
	@./mkconfig jz4780 m80701 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_M80701 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

m80701_tf_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_M80701 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile TF (MSC1) boot image for soc jz4780 m80701 BOARD"
	@./mkconfig jz4780 m80701 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_M80701 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

warrior_msc_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR070LA0S_270 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_WARRIOR 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define NO_CHARGE_DETE" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 warrior BOARD"
	@./mkconfig jz4780 warrior msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_WARRIOR = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

urboard_msc1_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_URBOARD 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 urboard BOARD"
	@./mkconfig jz4780 urboard msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_URBOARD = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

warrior_msc1_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR070LA0S_270 1" >> include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_WARRIOR 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 warrior BOARD"
	@./mkconfig jz4780 warrior msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_JZ4780_WARRIOR = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh novo7_1.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

npm801_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR080LA4S_250 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_NPM801 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_HAVE_CHARGE_LOGO" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 npm801 BOARD"
	@./mkconfig jz4780 npm801 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_NPM801 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_1024_768.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

t700d_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_SL007DC18B05 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_NPM801 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_NPM801_T700D 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_HAVE_CHARGE_LOGO" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 npm801 BOARD"
	@./mkconfig jz4780 npm801 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_NPM801 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_NPM801_T700D = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_1024_768.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

leaf_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_JCMT070T115A18 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_NPM801 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_NPM801_LEAF 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_HAVE_CHARGE_LOGO" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 npm801 BOARD"
	@./mkconfig jz4780 npm801 msc
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_NPM801 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_NPM801_LEAF = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_800_480.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c


npm801_msc1_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR080LA4S_250 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_NPM801 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 124568" >> include/config.h
	@echo "#define CONFIG_MSC_BURN" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 npm801 BOARD"
	@./mkconfig jz4780 npm801 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_MSC_BURN = y" >> include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_JZ4780_NPM801 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_1024_768.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

i88_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR080LA4S_250 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_I88 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 36468" >> include/config.h
	@echo "#define CONFIG_HAVE_CHARGE_LOGO" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4780 i88 BOARD"
	@./mkconfig jz4780 i88
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_JZ4780_I88 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_1024_768.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

i88_burner_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_KR080LA4S_250 1" >> include/config.h
	@echo "#define CONFIG_ANDROID_LCD_TFT_AT070TN93 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4780_LCDC1 1" >> include/config.h
	@echo "#define CONFIG_JZ4780 1" >> include/config.h
	@echo "#define CONFIG_JZ4780_I88 1" >> include/config.h
	@echo "#define CONFIG_MKBURNER 1" >> include/config.h
	@echo "#define CONFIG_CAPACITY 1700" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define I2C_BASE I2C1_BASE" >> include/config.h
	@echo "#define CONFIG_MSC_TYPE_MMC" >> include/config.h
	@echo "#define CONFIG_MSC1_BOOT" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 36468" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile MSC boot image for soc jz4780 i88 BOARD"
	@./mkconfig jz4780 i88 msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4780 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_JZ4780_I88 = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_1024_768.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

mensa_nand_config: unconfig
	@echo "#define CONFIG_NAND_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_BM800480_8766FTGU 1" >> include/config.h
#	@echo "#define CONFIG_LCD_KFM701A21_1A	1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4775_LCDC 1" >> include/config.h
#	@echo "#define CONFIG_LCD_FORMAT_X8B8G8R8 1" >> include/config.h
	@echo "#define CONFIG_JZ4775 1" >> include/config.h
	@echo "#define CONFIG_JZ4775_MENSA 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C2_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 36468" >> include/config.h
	@echo "#define CONFIG_HAVE_CHARGE_LOGO" >> include/config.h
#	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile nand boot image for soc jz4775 mensa BOARD"
	@./mkconfig jz4775 mensa
	@echo "CONFIG_NAND_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4775 = y" >> include/config.mk
	@echo "CONFIG_JZ4775_MENSA = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_LCD_BM800480_8766FTGU = y" >> include/config.mk
#	@echo "CONFIG_LCD_KFM701A21_1A = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_800_480.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c

mensa_msc_config: unconfig
	@echo "#define CONFIG_MSC_X_BOOT" > include/config.h
	@echo "#define CONFIG_LCD_BM800480_8766FTGU 1" >> include/config.h
	@echo "#define CONFIG_FB_JZ4775_LCDC 1" >> include/config.h
#	@echo "#define CONFIG_LCD_FORMAT_X8B8G8R8 1" >> include/config.h
	@echo "#define CONFIG_JZ4775 1" >> include/config.h
	@echo "#define CONFIG_JZ4775_MENSA 1" >> include/config.h
	@echo "#define CONFIG_SDRAM_DDR3" >> $(obj)include/config.h
	@echo "#define CONFIG_ACT8600" >> include/config.h
	@echo "#define FAST_BOOT_SUPPORT" >> include/config.h
	@echo "#define I2C_BASE I2C2_BASE" >> include/config.h
	@echo "#define CONFIG_XBOOT_POWERON_LONG_PRESSED 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE 1" >> include/config.h
	@echo "#define CONFIG_XBOOT_LOGO_FILE_LEN 36468" >> include/config.h
	@echo "#define CONFIG_HAVE_CHARGE_LOGO" >> include/config.h
#	@echo "#define CONFIG_XBOOT_LOW_BATTERY_DETECT" >> include/config.h
	@echo "Compile msc boot image for soc jz4775 mensa BOARD"
	@./mkconfig jz4775 mensa msc
	@echo "CONFIG_MSC_X_BOOT = y" > include/config.mk
	@echo "CONFIG_JZ4775 = y" >> include/config.mk
	@echo "CONFIG_JZ4775_MENSA = y" >> include/config.mk
	@echo "CONFIG_ACT8600 = y" >> include/config.mk
	@echo "CONFIG_POWER_MANAGEMENT = y" >> include/config.mk
	@echo "CONFIG_LCD_BM800480_8766FTGU = y" >> include/config.mk
	@echo "CONFIG_USE_DDR3 = y" >> include/config.mk
	@echo "./_mklogo.sh jz_800_480.rle" >> boot/mklogo.sh
	@ln -s ${PWD}/boot/common/jz_serial.c ${PWD}/spl/common/jz_serial.c
	@ln -s ${PWD}/boot/common/cpu.c ${PWD}/spl/common/cpu.c
	@ln -s ${PWD}/boot/common/debug.c ${PWD}/spl/common/debug.c
	@ln -s ${PWD}/boot/common/common.c ${PWD}/spl/common/common.c


release_config:
	echo "CONFIG_RELEASE = y" >> include/config.mk


#########################################################################
#########################################################################
#########################################################################

clean:
	$(MAKE) -C spl $@
	$(MAKE) -C boot $@
	$(MAKE) -C tools/security $@
	rm -f $(ALL)
	rm -rf ${PWD}/spl/common/jz_serial.c
	rm -rf ${PWD}/spl/common/cpu.c
	rm -rf ${PWD}/spl/common/debug.c
	rm -rf ${PWD}/spl/common/common.c
	rm -rf $(PWD)/include/config.mk
	rm -f *.bin
	rm -f *.sig
	rm -f crypto/*.bin
	@sed -i "s/#define CONFIG_SERIAL_DISABLE 1/#define CONFIG_SERIAL_DISABLE 0/" include/serial.h

distclean: clean
	rm -f crypto/*.key boot/public.binary boot/pack
	rm -f crypto/mkxbootimg crypto/pack crypto/sign_boot crypto/sign_kernel

########################################################################
