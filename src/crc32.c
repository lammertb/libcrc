/*
 * Library: libcrc
 * File:    src/crc32.c
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
 * The source file src/crc32.c contains the routines which are needed to
 * calculate a 32 bit CRC value of a sequence of bytes.
 */

#include <stdbool.h>
#include <stdlib.h>
#include "checksum.h"

static void             init_crc32_tab( void );

static bool             crc_tab32_init          = false;
static uint32_t		crc_tab32[256];

/*
 * uint32_t crc_32( const unsigned char *input_str, size_t num_bytes );
 *
 * The function crc_32() calculates in one pass the common 32 bit CRC value for
 * a byte string that is passed to the function together with a parameter
 * indicating the length.
 */

uint32_t crc_32( const unsigned char *input_str, size_t num_bytes ) {

	uint32_t crc;
	uint32_t tmp;
	uint32_t long_c;
	const unsigned char *ptr;
	size_t a;

	if ( ! crc_tab32_init ) init_crc32_tab();

	crc = CRC_START_32;
	ptr = input_str;

	if ( ptr != NULL ) for (a=0; a<num_bytes; a++) {

		long_c = 0x000000FFL & (uint32_t) *ptr;
		tmp    =  crc       ^ long_c;
		crc    = (crc >> 8) ^ crc_tab32[ tmp & 0xff ];

		ptr++;
	}

	crc ^= 0xffffffffL;

	return crc & 0xffffffffL;

}  /* crc_32 */

/*
 * uint32_t update_crc_32( uint32_t crc, unsigned char c );
 *
 * The function update_crc_32() calculates a new CRC-32 value based on the
 * previous value of the CRC and the next byte of the data to be checked.
 */

uint32_t update_crc_32( uint32_t crc, unsigned char c ) {

	uint32_t tmp;
	uint32_t long_c;

	long_c = 0x000000ffL & (uint32_t) c;

	if ( ! crc_tab32_init ) init_crc32_tab();

	tmp = crc ^ long_c;
	crc = (crc >> 8) ^ crc_tab32[ tmp & 0xff ];

	return crc & 0xffffffffL;;

}  /* update_crc_32 */

/*
 * static void init_crc32_tab( void );
 *
 * For optimal speed, the CRC32 calculation uses a table with pre-calculated
 * bit patterns which are used in the XOR operations in the program. This table
 * is generated once, the first time the CRC update routine is called.
 */

static void init_crc32_tab( void ) {

	uint32_t i;
	uint32_t j;
	uint32_t crc;

	for (i=0; i<256; i++) {

		crc = i;

		for (j=0; j<8; j++) {

			if ( crc & 0x00000001L ) crc = ( crc >> 1 ) ^ CRC_POLY_32;
			else                     crc =   crc >> 1;
		}

		crc_tab32[i] = crc;
	}

	crc_tab32_init = true;

}  /* init_crc32_tab */
