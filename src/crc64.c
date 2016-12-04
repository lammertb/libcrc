/*
 * Library: libcrc
 * File:    src/crc64.c
 * Author:  Lammert Bies
 *
 * This file is licensed under the MIT License as stated below
 *
 * Copyright (c) 2016 Lammert Bies
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
 * The source file src/crc64.c contains the routines which are needed to
 * calculate a 64 bit CRC value of a sequence of bytes.
 */

#include <stdbool.h>
#include <stdlib.h>
#include "checksum.h"

static void             init_crc64_tab( void );

static bool             crc_tab64_init          = false;
static uint64_t		crc_tab64[256];

/*
 * uint64_t crc_64_ecma( const unsigned char *input_str, size_t num_bytes );
 *
 * The function crc_64_ecma() calculates in one pass the ECMA 64 bit CRC value
 * for a byte string that is passed to the function together with a parameter
 * indicating the length.
 */

uint64_t crc_64_ecma( const unsigned char *input_str, size_t num_bytes ) {

	uint64_t crc;
	const unsigned char *ptr;
	size_t a;

	if ( ! crc_tab64_init ) init_crc64_tab();

	crc = CRC_START_64_ECMA;
	ptr = input_str;

	if ( ptr != NULL ) for (a=0; a<num_bytes; a++) {

		crc = (crc << 8) ^ crc_tab64[ ((crc >> 56) ^ (uint64_t) *ptr++) & 0x00000000000000FFull ];
	}

	return crc;

}  /* crc_64_ecma */

/*
 * uint64_t crc_64_we( const unsigned char *input_str, size_t num_bytes );
 *
 * The function crc_64_we() calculates in one pass the CRC64-WE 64 bit CRC
 * value for a byte string that is passed to the function together with a
 * parameter indicating the length.
 */

uint64_t crc_64_we( const unsigned char *input_str, size_t num_bytes ) {

	uint64_t crc;
	const unsigned char *ptr;
	size_t a;

	if ( ! crc_tab64_init ) init_crc64_tab();

	crc = CRC_START_64_WE;
	ptr = input_str;

	if ( ptr != NULL ) for (a=0; a<num_bytes; a++) {

		crc = (crc << 8) ^ crc_tab64[ ((crc >> 56) ^ (uint64_t) *ptr++) & 0x00000000000000FFull ];
	}

	return crc ^ 0xFFFFFFFFFFFFFFFFull;

}  /* crc_64_we */

/*
 * uint64_t update_crc_64( uint64_t crc, unsigned char c );
 *
 * The function update_crc_64() calculates a new CRC-64 value based on the
 * previous value of the CRC and the next byte of the data to be checked.
 */

uint64_t update_crc_64( uint64_t crc, unsigned char c ) {

	if ( ! crc_tab64_init ) init_crc64_tab();

	return (crc << 8) ^ crc_tab64[ ((crc >> 56) ^ (uint64_t) c) & 0x00000000000000FFull ];

}  /* update_crc_64 */

/*
 * static void init_crc64_tab( void );
 *
 * For optimal speed, the CRC64 calculation uses a table with pre-calculated
 * bit patterns which are used in the XOR operations in the program. This table
 * is generated once, the first time the CRC update routine is called.
 */

static void init_crc64_tab( void ) {

	uint64_t i;
	uint64_t j;
	uint64_t c;
	uint64_t crc;

	for (i=0; i<256; i++) {

		crc = 0;
		c   = i << 56;

		for (j=0; j<8; j++) {

			if ( ( crc ^ c ) & 0x8000000000000000ull ) crc = ( crc << 1 ) ^ CRC_POLY_64;
			else                                       crc =   crc << 1;

			c = c << 1;
		}

		crc_tab64[i] = crc;
	}

	crc_tab64_init = true;

}  /* init_crc64_tab */
