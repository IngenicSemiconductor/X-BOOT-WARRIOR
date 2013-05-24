/*
 * halEdid.h
 *
 *  Created on: Jul 5, 2010
 * 
 * Synopsys Inc.
 * SG DWC PT02
 */

#ifndef HALEDID_H_
#define HALEDID_H_

#include "../util/types.h"

/**
 *  Set the slave address in the I2CM registers.
 * @param baseAddr base address of the EDID module registers
 * @param addr the I2C slave address
 */
void halEdid_SlaveAddress(u16 baseAddr, u8 addr);

/** Set the address of the byte accessed at the slave device.
 * @param baseAddr base address of the EDID module registers
 * @param addr the address of the accessed byte
 */
void halEdid_RequestAddr(u16 baseAddr, u8 addr);

/** Write data that is to be sent to slave device
 * @param baseAddr base address of the EDID module registers
 * @param data a data byte to be sent to the slave device
 */
void halEdid_WriteData(u16 baseAddr, u8 data);

/** Read data received and stored in HW buffer.
 * @param baseAddr base address of the EDID module registers
 * @returns a read byte from the slave device
 */
u8 halEdid_ReadData(u16 baseAddr);

/** Send a read request to the slave device with the already requested address.
 */
void halEdid_RequestRead(u16 baseAddr);

/** Send an extended read request to the slave device with the already requested
 *  address (u16 baseAddr, E-DDC).
 * @param baseAddr base address of the EDID module registers
 */
void halEdid_RequestExtRead(u16 baseAddr);

/** Send a write request to the slave device with the already requested address
 *  and data to be written
 * @param baseAddr base address of the EDID module registers
 */
void halEdid_RequestWrite(u16 baseAddr);

/** Set the clock division from the SFR clock
 * @param baseAddr base address of the EDID module registers
 * @param value of clockl division (refer to HDMITXCTRL databook)
 */
void halEdid_MasterClockDivision(u16 baseAddr, u8 value);

/** Set the segment address. [to 0x60 for E-DDC (u16 baseAddr, EDID)].
 * @param baseAddr base address of the EDID module registers
 * @param addr segment address [set to 0x30 because HW inserts a 0 to the right]
 */
void halEdid_SegmentAddr(u16 baseAddr, u8 addr);

/** Set the segment pointer. (u16 baseAddr, should follow the formula N/2 where
 *  N is the block number).
 * @param baseAddr base address of the EDID module registers
 * @param pointer the pointer to the segment to be accessed.
 */
void halEdid_SegmentPointer(u16 baseAddr, u8 pointer);

/** Modify the error interrupt mask.
 * @param baseAddr base address of the EDID module registers
 * @param mask to enable or disable the masking (u16 baseAddr, true to mask,
 * ie true to stop seeing the interrupt).
 */
void halEdid_MaskInterrupts(u16 baseAddr, u8 mask);

/** Set the clock division from the SFR clock that are
 * required for setting the low time of the SCL clock in fast speed mode.
 * @param baseAddr base address of the EDID module registers
 * @param value of fast speed low time counter (refer to HDMITXCTRL databook)
 */
void halEdid_FastSpeedLowCounter(u16 baseAddr, u16 value);
/** Set the clock division from the SFR clock that are
 * required for setting the high time of the SCL clock in fast speed mode.
 * @param baseAddr base address of the EDID module registers
 * @param value of fast speed high time counter (refer to HDMITXCTRL databook)
 */
void halEdid_FastSpeedHighCounter(u16 baseAddr, u16 value);

/** Set the clock division from the SFR clock that are
 * required for setting the low time of the SCL clock in standard speed mode.
 * @param baseAddr base address of the EDID module registers
 * @param value of standard speed low time counter (refer to HDMITXCTRL databook)
 */
void halEdid_StandardSpeedLowCounter(u16 baseAddr, u16 value);

/** Set the clock division from the SFR clock that are
 * required for setting the high time of the SCL clock in standard speed mode.
 * @param baseAddr base address of the EDID module registers
 * @param value of standard speed high time counter (refer to HDMITXCTRL databook)
 */
void halEdid_StandardSpeedHighCounter(u16 baseAddr, u16 value);

#endif /* HALEDID_H_ */
