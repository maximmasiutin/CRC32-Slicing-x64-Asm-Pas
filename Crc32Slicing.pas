(*

CRC32 Slicing-By-8 Assembler IA-32 & x86-64 / Pascal implementation

Copyright 2020 Ritlabs, SRL

This code is released under GNU Lesser General Public License (LGPL) v3.

The Slicing-By-8 x86-64 Assembler version and Pascal version is written by
Maxim Masiutin <max@ritlabs.com>

Based on code written by Aleksandr Sharahov http://guildalfa.ru/alsha/node/2 ;
Based on code from "Synopse mORMot framework" https://synopse.info/ ;
Based on code by Intel Corp. https://sourceforge.net/projects/slicing-by-8 .

IA-32 or x86-64 assembler code has 1,20 CPU clock cycles (on Skylake) per byte of data.

This code is used in "The Bat!" email client
https://www.ritlabs.com/en/products/thebat/

Define PUREPASCAL if you wish to compile Pascal implementation.
Otherwise, the Assembler implementation will be compiled.

Can be compiled by Delphi or Free Pascal Compiler (FPC).

If you define SLICING_BY_4, the Pascal implementation of Slicing-By-4
will be compiled instead (there is no assembler implementation 
of Slicing-By-4).

The "crc32_slicing" function that has the following inputs:
buffer (pointer); 
length (unsigned integer, 32 or 64 bits depending on platform, highest bit must be zero); 
crc (32-bit unsigned integer) - initial value;
table (or 4K for Slicing-by-4) (pointer) - the pre-computed look-up table of 8K, see InitCrc32SlicingByNTable in CrcTest.dpr on how to fill this table.
output: crc (32-bit unsigned integer).

Assembler implementation of "crc32_slicing" takes parameters in the following registers.
For IA-32: eax - buffer, edx - length, ecx - crc, 32-bits in stack - table; on return eax will contain output crc;
For x86-64: rcx - buffer, rdx - length, r8 - crc, r9 - table; on return rax will contain output crc.



*)


unit Crc32Slicing;

interface

{$IFDEF FPC}
  {$ASMMODE INTEL}
{$ENDIF}

{$IFDEF SLICING_BY_4}
  {$DEFINE PUREPASCAL}
{$ENDIF}

{$IFDEF FPC}
  type
    Crc32NativeUInt = NativeUInt;
{$ELSE}
  {$IFDEF DELPHI_XE}
  type
    Crc32NativeUInt = NativeUInt;
  {$ELSE}
  type
    Crc32NativeUInt = Cardinal;
  {$ENDIF}
{$ENDIF}


type
  TCrc32SlicingByNTable = packed array[0..{$IFDEF SLICING_BY_4}4{$ELSE}8{$ENDIF}-1,Byte] of Cardinal;
  PCrc32SlicingByNTable = ^TCrc32SlicingByNTable;

function crc32_slicing(const Abuf; const ALength: Crc32NativeUInt; crc: Cardinal; const Acrc32FastTable: PCrc32SlicingByNTable): Cardinal; register;

implementation

function crc32_slicing(const Abuf; const ALength: Crc32NativeUInt; crc: Cardinal; const Acrc32FastTable: PCrc32SlicingByNTable): Cardinal; register;
{$IFDEF PUREPASCAL}

const
  CAlignmentMask =
      {$IFDEF SLICING_BY_4}
        3
      {$ELSE}
        {$IFDEF WIN64}
          7 // under Win64 and Slicing-by-8 we align to 8-byte boundary; otherwise to 4-byte boundary
        {$ELSE}
          3
        {$ENDIF}
      {$ENDIF}
  ;

var
  buf: PAnsiChar;
  len: Crc32NativeUInt;

{$IFNDEF SLICING_BY_4}
  Term2: Cardinal;
  {$IFDEF WIN64}
    U64: UInt64;
  {$ENDIF}
{$ENDIF SLICING_BY_4}

begin
  len := ALength;
  buf := @ABuf;
  Result := crc;
  if (buf <> nil) and (len > 0) then
  begin

// align source buffer to 4 or 8 bytes boundary
    repeat
      if (Crc32NativeUInt(buf) and CAlignmentMask) = 0 then
        Break;
      Result := Acrc32FastTable^[0, Byte(Result xor Ord(buf^))] xor (Result shr 8);
      Dec(len);
      Inc(buf);
    until len=0;


    {$IFDEF SLICING_BY_4}

(*

Slicing-by-4 source code taken from "Synopse mORMot framework" at https://synopse.info/
SynCommons.pas, crc32cfast

Slicing-by-4 code is given here only to be able to compare its speed with Slicing-by-8

Here are the results for a Skylake CPU, clock cycles per byte (smaller is better):

Slicing-by-8, assembler (64-bit): 1,20
Slicing-by-8, assembler (32-bit): 1,20

Slicing-by-8, Delphi (64-bit): 1,84
Slicing-by-8, Delphi (32-bit): 1,82

Slicing-by-4, Delphi (64-bit): 2,68
Slicing-by-4, Delphi (32-bit): 2,69

The clock/per/byte ratio of binary produced by Free Pascal Compiler (FPC) 3.0.4 was 
worse then of that produced by Delphi 10.3.3, so I didn't include the results.

*)

    while len>=4 do
    begin
      Result := Result xor PCardinal(buf)^;
      Inc(buf,4);
      Result := Acrc32FastTable^[3, Byte(Result)] xor
                Acrc32FastTable^[2, Byte(Result shr 8)] xor
                Acrc32FastTable^[1, Byte(Result shr 16)] xor
                Acrc32FastTable^[0, Result shr 24];
      Dec(len,4);
    end;

    {$ELSE}

    // Slicing-by-8 idea is taken from the original Intel Slicing-by-8 code (released in 2006)
    // available on sourceforge.net/projects/slicing-by-8

    while len >= 8 do
    begin
      {$IFDEF WIN64}
      U64 := PUint64(buf)^;
      Result := Result xor Cardinal(U64);
      Term2 := U64 shr 32;
      Inc(buf, 8);
      {$ELSE}
      Result := Result xor PCardinal(buf)^;
      Inc(buf,4);
      Term2 := PCardinal(buf)^;
      Inc(buf,4);
      {$ENDIF}
      Dec(len,8);

      Result := Acrc32FastTable^[7, Byte(Result)] xor
                Acrc32FastTable^[6, Byte(Result shr 8)] xor
                Acrc32FastTable^[5, Byte(Result shr 16)] xor
                Acrc32FastTable^[4, Result shr 24] xor
                Acrc32FastTable^[3, Byte(Term2)] xor
                Acrc32FastTable^[2, Byte(Term2 shr 8)] xor
                Acrc32FastTable^[1, Byte(Term2 shr 16)] xor
                Acrc32FastTable^[0, Term2 shr 24];
    end;


    {$ENDIF}

    while len>0 do
    begin
      Result := Acrc32FastTable^[0, Byte(Result xor Ord(buf^))] xor (Result shr 8);
      dec(Len);
      inc(Buf);
    end;
  end;
end;

{$else}

 assembler;

// Slicing-by-8 assembler implementation
// adapted from fast Aleksandr Sharahov version ( http://guildalfa.ru/alsha/node/2 ) released in 2009

// Of that version, second iteration of loop unrolling was removed because testing demonstrated it had no benefit,
// or even made code slower because of a branch in the middle that could cause branch misprediction penalty.


// See also the "High Octane CRC Generation with the Intel Slicing-by-8 Algorithm" white paper published by Intel in 2006

{$IFDEF WIN64}

// under Win64, function arguments come in the following registers:
// first - RCX, second - RDX, third R8, fourth - R9
// return - RAX
// the following registers may be destroyed after the call: RAX,RCX,RDX,R8,R9,R10:R11
// https://msdn.microsoft.com/en-us/library/ms235286.aspx

// Under Win32, a call passes first parameter in EAX, second in EDX, third in ECX

//             64     32
//             ---   ---
//        1)   rcx   eax
//        2)   rdx   edx
//        3)   r8    ecx
//        4)   r9    [stack]
asm
// rcx has buf, rdx las len, r8 has crc, r9 has table

        test    rcx, rcx // null pointer comparison
        jz      @exit

        cmp     rdx, 8
        jge     @big
        test    rdx, rdx
        jle     @exit  // negative value or zero // ZF = 1 or SF <> OF

        mov     r8d, r8d  // clear higher bits of r8 that keeps current CRC32, see http://stackoverflow.com/questions/43964922/is-mov-r8d-r8d-a-legitimate-long-term-way-to-clear-higher-bits-32-63-of-a-64

// if we have 7 bytes or less, calculate them old-fashioned way

@calc_crc32:
        xor     r8b,byte ptr [rcx] // get next byte from the source buffer
        inc     rcx
        movzx   r10d, r8b
        shr     r8d, 8
        xor     r8d, dword ptr [r9+r10*4 + 1024 * 0] // use just "classic" 1024-bytes table of 256 elements of 32 bits
        dec     rdx
        jnz     @calc_crc32

        mov     eax, r8d
        jmp     @exit

@big:

        mov     eax, r8d  // now rax has crc, higher bits are again cleared by this move

        neg     rdx       // now we have negative length

// align source buffer by 8 bytes under 64-bit
        test    cl, 7
        jz      @aligned

@unaligned:
        xor     al,byte ptr [rcx] // get next byte from the source buffer
        inc     rcx
        movzx   r10d, al
        shr     eax, 8
        xor     eax, dword ptr [r9+r10*4 + 1024 * 0] // use just "classic" 1024-bytes table of 256 elements of 32 bits
        inc     rdx
        test    cl, 7
        jnz     @unaligned

@aligned:
        sub     rcx, rdx
        add     rdx, 8
        mov     r10, rdx   // now we have negative length in r10
        jg      @check_tail

@block_loop:

        mov     edx, eax  // this also sets the rest of rdx (bits 32-63) to zero

        mov     r11, qword ptr[rcx + r10 - 8] // get next 8 bytes (as QWORD) from the input buffer
        xor     edx, r11d
        mov     r8,  r11
        shr     r8,  32

        movzx   r11d, r8b
        shr     r8d, 8
        mov     eax, dword ptr[r11 * 4 + r9 + 1024 * 3]
        movzx   r11d, r8b
        shr     r8d, 8
        xor     eax, dword ptr[r11 * 4 + r9 + 1024 * 2]
        movzx   r11d, r8b
        shr     r8d, 8
        xor     eax, dword ptr[r11 * 4 + r9 + 1024 * 1]
        xor     eax, dword ptr[r8  * 4 + r9 + 1024 * 0]

        movzx   r11d, dl
        shr     edx, 8
        xor     eax, dword ptr[r11 * 4 + r9 + 1024 * 7]
        movzx   r11d, dl
        shr     edx, 8
        xor     eax, dword ptr[r11 * 4 + r9 + 1024 * 6]
        movzx   r11d, dl
        shr     edx, 8
        xor     eax, dword ptr[r11 * 4 + r9 + 1024 * 5]
        xor     eax, dword ptr[rdx * 4 + r9 + 1024 * 4]

        add     r10, 8
        jle     @block_loop

@check_tail:
        sub     r10, 8
        jnl     @exit

@tail_loop:
        movzx   r8, byte[rcx + r10]
        xor     r8b, al
        shr     eax, 8
        xor     eax, dword ptr[r8 * 4 + r9 + 1024 * 0]
        inc     r10
        jnz     @tail_loop
@exit:
end;


{$ELSE !WIN64}

// Under Win32, a call passes first parameter in EAX, second in EDX, third in ECX
// result is returned in EAX
// procedures and functions must preserve the EBX, ESI, EDI, and EBP registers, but can modify the EAX, EDX, and ECX registers.
// http://docwiki.embarcadero.com/RADStudio/Seattle/en/Program_Control#Register_Convention

asm
//        buf = eax, len = edx, crc = ecx

        test    eax, eax // null pointer comparison
        jz      @@exit
        cmp     edx, 8
        jge     @big
        test    edx, edx
        jle     @@exit // exit if length is negative value or zero // ZF = 1 or SF <> OF

// length is 7 bytes or less - calculate byte-by-byte and exit
        push    edi
        push    ebx
        mov     edi, ss:[ebp + 8] // 8 - stack offset of fourth argument
@calc_crc32:
        xor     cl,[eax]
        inc     eax
        movzx   ebx,cl
        shr     ecx,8
        xor     ecx,dword ptr [edi+ebx*4]
        dec     edx
        jnz     @calc_crc32
        mov     eax, ecx
        pop     ebx
        pop     edi
        jmp     @@exit

@big:
        neg     edx

        push    ebx
        push    esi

        mov     esi, edx // save "length" (negative) to esi
        mov     edx, eax // now edx has "buf"
        mov     eax, ecx // now eax has "crc"
        mov     ecx, esi // now ecx has "length" (negative)

        mov     esi, ss:[ebp + 8] // 8 - stack offset of fourth argument

// align by 4 bytes under Win32
        test    dl, 3
        jz      @aligned

@unaligned:
        movzx   ebx, byte[edx]
        inc     edx
        xor     bl, al
        shr     eax, 8
        xor     eax, dword ptr[ebx * 4 + esi]
        inc     ecx
        test    dl, 3
        jnz     @unaligned

@aligned:
        sub     edx, ecx
        add     ecx, 8
        jg      @check_tail
        push    ebp
        push    edi
        mov     ebp, esi
        mov     edi, edx

@block_loop:
        mov     edx, eax
        mov     ebx, [edi + ecx - 4]
        xor     edx, [edi + ecx - 8]

        movzx   esi, bl
        shr     ebx, 8
        mov     eax, dword ptr ds:[esi * 4 + ebp + 1024 * 3]
        movzx   esi, bl
        shr     ebx, 8
        xor     eax, dword ptr ds:[esi * 4 + ebp + 1024 * 2]
        movzx   esi, bl
        shr     ebx, 8
        xor     eax, dword ptr ds:[esi * 4 + ebp + 1024 * 1]
        xor     eax, dword ptr ds:[ebx * 4 + ebp + 1024 * 0]

        movzx   esi, dl
        shr     edx, 8
        xor     eax, dword ptr ds:[esi * 4 + ebp + 1024 * 7]
        movzx   esi, dl
        shr     edx, 8
        xor     eax, dword ptr ds:[esi * 4 + ebp + 1024 * 6]
        movzx   esi, dl
        shr     edx, 8
        xor     eax, dword ptr ds:[esi * 4 + ebp + 1024 * 5]
        xor     eax, dword ptr ds:[edx * 4 + ebp + 1024 * 4]

        add     ecx, 8
        jle     @block_loop

        mov     edx, edi
        pop     edi
        pop     ebp

@check_tail:
        sub     ecx, 8
        jnl     @@pop_exit

        mov     esi, ss:[ebp + 8] // 8 - stack offset of fourth argument
@tail_loop:
        movzx   ebx, byte[edx + ecx]
        xor     bl, al
        shr     eax, 8
        xor     eax, dword ptr ds:[ebx * 4 + esi]
        inc     ecx
        jnz     @tail_loop
@@pop_exit:
        pop     esi
        pop     ebx
@@exit:
end;
{$ENDIF WIN64}
{$endif PUREPASCAL}


end.
