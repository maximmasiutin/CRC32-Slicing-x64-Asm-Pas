# CRC32 Slicing-By-8 Assembler x64 / Pascal
CRC32 Slicing-By-8 Assembler IA-32 & x86-64 / Pascal implementation

Copyright (C) 2020 Ritlabs, SRL. All rights reserved.
Copyright (C) 2020-2025 Maxim Masiutin. All rights reserved.

This code is released under GNU Lesser General Public License (LGPL) v3.

The Slicing-By-8 x86-64 Assembler version and Pascal version is written by
Maxim Masiutin <maxim.masiutin@gmail.com>

Based on code written by Aleksandr Sharahov http://guildalfa.ru/alsha/node/2 ;
Based on code from "Synopse mORMot framework" https://synopse.info/ ;
Based on code by Intel Corp. https://sourceforge.net/projects/slicing-by-8 .

IA-32 or x86-64 assembler code has 1,20 CPU clock cycles (on Skylake) per byte of data.

Define PUREPASCAL if you wish to compile Pascal implementation.
Otherwise, the Assembler implementation will be compiled.

Can be compiled by Delphi or Free Pascal Compiler (FPC) on Windows and Linux.

If you define SLICING_BY_4, the Pascal implementation of Slicing-By-4
will be compiled instead (there is no assembler implementation
of Slicing-By-4).

## Docker Testing

Run tests in a Docker container with FPC on Linux:
```
docker build -t crc32-test .
docker run --rm crc32-test
```

This tests three configurations: x86-64 assembler, pure Pascal, and Slicing-By-4.

The "crc32_slicing" function that has the following inputs:
buffer (pointer);
length (unsigned integer, 32 or 64 bits depending on platform, highest bit must be zero);
crc (32-bit unsigned integer) - initial value;
table (or 4K for Slicing-by-4) (pointer) - the pre-computed look-up table of 8K, see InitCrc32SlicingByNTable in CrcTest.dpr on how to fill this table.
output: crc (32-bit unsigned integer).

Assembler implementation of "crc32_slicing" takes parameters in the following registers.
For IA-32: eax - buffer, edx - length, ecx - crc, 32-bits in stack - table; on return eax will contain output crc;
For x86-64 Windows: rcx - buffer, rdx - length, r8 - crc, r9 - table; on return rax will contain output crc;
For x86-64 Linux (System V ABI): rdi - buffer, rsi - length, rdx - crc, rcx - table; on return rax will contain output crc.
