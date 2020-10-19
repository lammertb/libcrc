/*
 * Library: libcrc
 * File:    src/crcccitt32.c
 * Author:  Lammert Bies
 *
 * This file is licensed under the MIT License as stated below
 *
 * Copyright (c) 1999-2016 Lammert Bies
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Description
 * -----------
 * The module src/crcccitt32.c contains routines which are used to calculate the
 * CCITT32 CRC values of a string of bytes.
 */

#include <stdbool.h>
#include <stdlib.h>
#include "checksum.h"

static uint32_t         crc_ccitt32_generic( const unsigned char *input_str, size_t num_bytes, uint32_t start_value );
static void             init_crcccitt32_tab( uint32_t poly, uint32_t swapped);

static bool             crc_tabccitt32_init       = false;
static uint32_t         crc_tabccitt32[256];

/*
 * uint32_t crc_ccitt32_ffffffff( const unsigned char *input_str, size_t num_bytes );
 *
 * The function crc_ccitt32_ffffffff() performs a one-pass calculation of the CCITT
 * CRC for a byte string that has been passed as a parameter. The initial value
 * 0xffffffff is used for the CRC.
 */

uint32_t crc_ccitt32_ffffffff( const unsigned char *input_str, size_t num_bytes ) {

	return crc_ccitt32_generic( input_str, num_bytes, CRC_START_CCITT32_FFFFFFFF );

}  /* crc_ccitt32_ffffffff */

/*
 * static uint32_t crc_ccitt32_generic( const unsigned char *input_str, size_t num_bytes, uint32_t start_value );
 *
 * The function crc_ccitt32_generic() is a generic implementation of the CCITT32
 * algorithm for a one-pass calculation of the CRC for a byte string. The
 * function accepts an initial start value for the crc.
 */

static uint32_t crc_ccitt32_generic( const unsigned char *input_str, size_t num_bytes, uint32_t start_value ) {

	uint32_t crc;
	const unsigned char *ptr;
	size_t a;

	if ( ! crc_tabccitt32_init ) init_crcccitt32_tab(CRC_POLY_CCITT32, 0);

	crc = start_value;
	ptr = input_str;

	if ( ptr != NULL ) for (a=0; a<num_bytes; a++) {

		crc = ((crc << 8)&0xffffff00) ^ crc_tabccitt32[ (((crc >> 24)&0xff) ^ *ptr++) ];
	}

	return crc;

}  /* crc_ccitt32_generic */

/*
 * uint32_t update_crc_ccitt32( uint32_t crc, unsigned char c );
 *
 * The function update_crc_ccitt32() calculates a new CRC-CCITT32 value based on
 * the previous value of the CRC and the next byte of the data to be checked.
 */

uint32_t update_crc_ccitt32( uint32_t crc, unsigned char c ) {

	if ( ! crc_tabccitt32_init ) init_crcccitt32_tab(CRC_POLY_CCITT32, 0);

	return ((crc << 8)&0xffffff00) ^ crc_tabccitt32[ ((crc >> 24) ^ c) & 0xff ];

}  /* update_crc_ccitt32 */

/*
 * static void init_crcccitt32_tab( void );
 *
 * For optimal performance, the routine to calculate the CRC-CCITT32 uses a
 * lookup table with pre-compiled values that can be directly applied in the
 * XOR action. This table is created at the first call of the function by the
 * init_crcccitt32_tab() routine.
 */

static void init_crcccitt32_tab( uint32_t poly, uint32_t swapped) {

	int i;
	int j;
	uint32_t crc;

	for (i=0; i<256; i++) {
		if(swapped) {
			crc = crc & 1 ? (crc >> 1)^poly : crc >> 1;
			for (crc=i,j=8; --j >=0 ;) {
				crc = crc & 1 ? (crc >> 1)^poly : crc >> 1;
			}
		}
		else {
			for (crc=i<<24, j=8; --j >= 0;) {
				crc = crc & 0x80000000 ? (crc << 1)^poly : crc << 1;
			}
		}
		crc_tabccitt32[i] = crc;
	}

	crc_tabccitt32_init = true;

}  /* init_crcccitt32_tab */
