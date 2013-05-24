#ifndef __NAND_CONFIG_H
#define __NAND_CONFIG_H

/*
 *  * This file contains the nand configuration parameters for the cygnus board.
 *   */
/*-----------------------------------------------------------------------
 *  * NAND FLASH configuration
 *   */

#define CONFIG_NAND_K9HBG08U1M

#define CFG_NAND_BCH_BIT        4               /* Speif () {
						   y the hardware BCH algorithm for nand (4|8) */
#define CFG_NAND_BW8            1               /* Data bus width: 0-16bit, 1-8bit */
#define CFG_NAND_PAGE_SIZE      2048
#define CFG_NAND_OOB_SIZE       64             /* Size of OOB space per page (e.g. 64 128 etc.) */
#define CFG_NAND_ROW_CYCLE      3
#define CFG_NAND_BLOCK_SIZE     (256 << 10)     /* NAND chip block size         */
#define CFG_NAND_BADBLOCK_PAGE  0             /* NAND bad block was marked at this page in a block, starting from 0 */

#endif /* __NAND_CONFIG_H */
