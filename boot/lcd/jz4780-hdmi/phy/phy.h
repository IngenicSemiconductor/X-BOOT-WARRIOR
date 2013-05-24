/*
 * phy.h
 *
 *  Synopsys Inc.
 *  SG DWC PT02
 */
/**
 * @file
 * Physical line interface configuration
 */
#ifndef PHY_H_
#define PHY_H_

#include "../util/types.h"

/* #define PHY_THIRD_PARTY */
#define PHY_GEN2_TSMC_40LP_2_5V  /* TQL */
/* #define PHY_GEN2_TSMC_40G_1_8V */  /* E102 */
//#define PHY_GEN2_TSMC_65LP_2_5V  /* E104 */
/* #define PHY_TNP */ /* HDMI 1.3 Tx PHY 2.25Gbps in TSMC 65nm GP 2.5V */
/* #define PHY_CNP */ /* HDMI 1.3 Tx PHY 2.25Gbps in Chartered 65nm LPe 2.5V */

/* phy pll lock timeout */
#define PHY_TIMEOUT 1000
/** Initialise phy and put into a known state
 * @param baseAddr of controller
 * @param dataEnablePolarity data enable polarity
 */
int phy_Initialize(u16 baseAddr, u8 dataEnablePolarity);
/** Bring up PHY and start sending media for a specified pixel clock, pixel
 * repetition and colour resolution (to calculate TMDS)
 * @param baseAddr of controller
 * @param pClk pixel clock
 * @param cRes colour depth or colour resolution (bits/component/pixel)
 * @param pRep pixel repetition
 */
int phy_Configure (u16 baseAddr, u16 pClk, u8 cRes, u8 pRep);
/** Set PHY to standby mode - turn off all interrupts
 * @param baseAddr of controller
 */
int phy_Standby(u16 baseAddr);
/** Enable HPD sensing ciruitry
 * @param baseAddr of controller
 */
int phy_EnableHpdSense(u16 baseAddr);
/** Disable HPD sensing ciruitry
 * @param baseAddr of controller
 */
int phy_DisableHpdSense(u16 baseAddr);
/**
 * Detects the signal on the HPD line and
 * upon change, it inverts polarity of the interrupt
 * bit so that interrupt raises only on change
 * @param baseAddr of controller
 * @return TRUE the HPD line is asserted
 */
int phy_HotPlugDetected(u16 baseAddr);
/**
 * @param baseAddr of controller
 * @param value of mask of interrupt register
 */
int phy_InterruptEnable(u16 baseAddr, u8 value);
/**
 * @param baseAddr of controller
 * @param value
 */
int phy_TestControl(u16 baseAddr, u8 value);
/**
 * @param baseAddr of controller
 * @param value
 */
int phy_TestData(u16 baseAddr, u8 value);
/**
 * @param baseAddr of controller
 * @param data
 * @param addr of register offset in PHY register bank (through I2C)
 */
int phy_I2cWrite(u16 baseAddr, u16 data, u8 addr);

int phy_I2cRead(u16 baseAddr, u16 *data, u8 addr);

#endif /* PHY_H_ */
