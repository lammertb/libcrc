/*
 * Library: libcrc
 * File:    examples/tstcrc.c
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
 * The file tstx_crc.c contains a small sample program which demonstrates the
 * use of the functions for calculating the CRC-CCITT, CRC-16 and CRC-32 values
 * of data. The program calculates the three different CRC's for a file who's
 * name is either provided at the command line, or data typed in right the
 * program has started.
 */



#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../include/checksum.h"



#define MAX_STRING_SIZE	2048



void main( int argc, char *argv[] ) {

	char input_string[MAX_STRING_SIZE];
	char *ptr;
	char *dest;
	char hex_val;
	char prev_byte;
	uint16_t crc_16;
	uint16_t crc_16_modbus;
	uint16_t crc_ccitt_ffff;
	uint16_t crc_ccitt_0000;
	uint16_t crc_ccitt_1d0f;
	uint16_t crc_dnp;
	uint16_t crc_sick;
	uint16_t crc_kermit;
	uint16_t low_byte;
	uint16_t high_byte;
	uint32_t crc_32;
	int a, ch;
	bool do_ascii;
	bool do_hex;
	FILE *fp;

	do_ascii = false;
	do_hex   = false;

	printf( "\ntstcrc: CRC algorithm sample program\nCopyright (c) 1999-2016 Lammert Bies\n\n" );

	if ( argc < 2 ) {

		printf( "Usage: tst_crc [-a|-x] file1 ...\n\n" );
		printf( "    -a Program asks for ASCII input. Following parameters ignored.\n" );
		printf( "    -x Program asks for hexadecimal input. Following parameters ignored.\n" );
		printf( "       All other parameters are treated like filenames. The CRC values\n" );
		printf( "       for each separate file will be calculated.\n" );

		exit( 0 );
	}

	if ( ! strcmp( argv[1], "-a" )  ||  ! strcmp( argv[1], "-A" ) ) do_ascii = true;
	if ( ! strcmp( argv[1], "-x" )  ||  ! strcmp( argv[1], "-X" ) ) do_hex   = true;

	if ( do_ascii  ||  do_hex ) {

		printf( "Input: " );
		fgets( input_string, MAX_STRING_SIZE-1, stdin );
	}

	if ( do_ascii ) {

		ptr = input_string;
		while ( *ptr  &&  *ptr != '\r'  &&  *ptr != '\n' ) ptr++;
		*ptr = 0;
	}

	if ( do_hex ) {

		ptr  = input_string;
		dest = input_string;

		while( *ptr  &&  *ptr != '\r'  &&  *ptr != '\n' ) {

			if ( *ptr >= '0'  &&  *ptr <= '9' ) *dest++ = (char) ( (*ptr) - '0'      );
			if ( *ptr >= 'A'  &&  *ptr <= 'F' ) *dest++ = (char) ( (*ptr) - 'A' + 10 );
			if ( *ptr >= 'a'  &&  *ptr <= 'f' ) *dest++ = (char) ( (*ptr) - 'a' + 10 );

			ptr++;
		}

		* dest    = '\x80';
		*(dest+1) = '\x80';
	}



	a = 1;

	do {

		crc_16         = 0x0000;
		crc_16_modbus  = 0xffff;
		crc_dnp        = 0x0000;
		crc_sick       = 0x0000;
		crc_ccitt_0000 = 0x0000;
		crc_ccitt_ffff = 0xffff;
		crc_ccitt_1d0f = 0x1d0f;
		crc_kermit     = 0x0000;
		crc_32         = 0xffffffffL;



		if ( do_ascii ) {

			prev_byte = 0;
			ptr       = input_string;

			while ( *ptr ) {

				crc_16         = update_crc_16(     crc_16,         *ptr            );
				crc_16_modbus  = update_crc_16(     crc_16_modbus,  *ptr            );
				crc_dnp        = update_crc_dnp(    crc_dnp,        *ptr            );
				crc_sick       = update_crc_sick(   crc_sick,       *ptr, prev_byte );
				crc_ccitt_0000 = update_crc_ccitt(  crc_ccitt_0000, *ptr            );
				crc_ccitt_ffff = update_crc_ccitt(  crc_ccitt_ffff, *ptr            );
				crc_ccitt_1d0f = update_crc_ccitt(  crc_ccitt_1d0f, *ptr            );
				crc_kermit     = update_crc_kermit( crc_kermit,     *ptr            );
				crc_32         = update_crc_32(     crc_32,         *ptr            );

				prev_byte = *ptr;
				ptr++;
			}
		}



		else if ( do_hex ) {

			prev_byte = 0;
			ptr       = input_string;

			while ( *ptr != '\x80' ) {

				hex_val  = (char) ( ( * ptr     &  '\x0f' ) << 4 );
				hex_val |= (char) ( ( *(ptr+1)  &  '\x0f' )      );

				crc_16         = update_crc_16(     crc_16,         hex_val            );
				crc_16_modbus  = update_crc_16(     crc_16_modbus,  hex_val            );
				crc_dnp        = update_crc_dnp(    crc_dnp,        hex_val            );
				crc_sick       = update_crc_sick(   crc_sick,       hex_val, prev_byte );
				crc_ccitt_0000 = update_crc_ccitt(  crc_ccitt_0000, hex_val            );
				crc_ccitt_ffff = update_crc_ccitt(  crc_ccitt_ffff, hex_val            );
				crc_ccitt_1d0f = update_crc_ccitt(  crc_ccitt_1d0f, hex_val            );
				crc_kermit     = update_crc_kermit( crc_kermit,     hex_val            );
				crc_32         = update_crc_32(     crc_32,         hex_val            );

				prev_byte = hex_val;
				ptr      += 2;
			}

			input_string[0] = 0;
		}



		else {

			prev_byte = 0;
#if defined(_MSC_VER)
			fp = NULL;
			fopen_s( & fp, argv[a], "rb" );
#else
			fp = fopen( argv[a], "rb" );
#endif

			if ( fp != NULL ) {

				while( ( ch=fgetc( fp ) ) != EOF ) {

					crc_16         = update_crc_16(     crc_16,         (char) ch            );
					crc_16_modbus  = update_crc_16(     crc_16_modbus,  (char) ch            );
					crc_dnp        = update_crc_dnp(    crc_dnp,        (char) ch            );
					crc_sick       = update_crc_sick(   crc_sick,       (char) ch, prev_byte );
					crc_ccitt_0000 = update_crc_ccitt(  crc_ccitt_0000, (char) ch            );
					crc_ccitt_ffff = update_crc_ccitt(  crc_ccitt_ffff, (char) ch            );
					crc_ccitt_1d0f = update_crc_ccitt(  crc_ccitt_1d0f, (char) ch            );
					crc_kermit     = update_crc_kermit( crc_kermit,     (char) ch            );
					crc_32         = update_crc_32(     crc_32,         (char) ch            );

					prev_byte = (char) ch;
				}

				fclose( fp );
			}

			else printf( "%s : cannot open file\n", argv[a] );
		}



		crc_32    ^= 0xffffffffL;

		crc_dnp    = ~crc_dnp;
		low_byte   = (crc_dnp    & 0xff00) >> 8;
		high_byte  = (crc_dnp    & 0x00ff) << 8;
		crc_dnp    = low_byte | high_byte;

		low_byte   = (crc_sick   & 0xff00) >> 8;
		high_byte  = (crc_sick   & 0x00ff) << 8;
		crc_sick   = low_byte | high_byte;

		low_byte   = (crc_kermit & 0xff00) >> 8;
		high_byte  = (crc_kermit & 0x00ff) << 8;
		crc_kermit = low_byte | high_byte;

		printf( "%s%s%s :\nCRC16              = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC16 (Modbus)     = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC16 (Sick)       = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC-CCITT (0x0000) = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC-CCITT (0xffff) = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC-CCITT (0x1d0f) = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC-CCITT (Kermit) = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC-DNP            = 0x%04" PRIX16 "      /  %" PRIu16 "\n"
				  "CRC32              = 0x%08" PRIX32 "  /  %" PRIu32 "\n"
				, (   do_ascii  ||    do_hex ) ? "\""    : ""
				, ( ! do_ascii  &&  ! do_hex ) ? argv[a] : input_string
				, (   do_ascii  ||    do_hex ) ? "\""    : ""
				, crc_16,         crc_16
				, crc_16_modbus,  crc_16_modbus
				, crc_sick,       crc_sick
				, crc_ccitt_0000, crc_ccitt_0000
				, crc_ccitt_ffff, crc_ccitt_ffff
				, crc_ccitt_1d0f, crc_ccitt_1d0f
				, crc_kermit,     crc_kermit
				, crc_dnp,        crc_dnp
				, crc_32,         crc_32     );

		a++;

	} while ( a < argc );

}  /* main (tstcrc.c) */
