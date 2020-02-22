program CrcTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Crc32Slicing in 'Crc32Slicing.pas';

const
  { CRC-32-IEEE }
  cCrc32IeeePoly = $EDB88320; // Generator polynomial number
  cCrc32IeeeInit = $FFFFFFFF; // Initial CRC value for calculation
  cCrc32IeeeTest = $DEBB20E3; // Result to test for at receiver

  { CRC-32C (Castagnoli) }
  cCrc32CastagnoliPoly = $82f63b78;
  cCrc32CastagnoliInit = $00000000; // Initial CRC value for calculation

var
  FCrc32IeeeTable,
  FCrc32CastagnoliTable: PCrc32SlicingByNTable;

procedure InitCrc32SlicingByNTable(var ACrc32SlicingByNTable: PCrc32SlicingByNTable; const APoly: Cardinal);

// source code of the Slicing-By-N table initialization
// is adapted from Aleksandr Sharahov's version ( http://guildalfa.ru/alsha/node/4 ) released in 2009
// ShaCRC32.zip, ShaCrcUnit.pas

var
  i, n, c: Cardinal;
begin
  if Assigned(ACrc32SlicingByNTable) then Exit;

  GetMem(ACrc32SlicingByNTable, SizeOf(TCrc32SlicingByNTable));
  FillChar(ACrc32SlicingByNTable^, SizeOf(TCrc32SlicingByNTable), 0);
  for i := 0 to 255 do
  begin
    c := i;
    for n := 1 to 8 do
    begin
      if Odd(c) then
      begin
        c := (c shr 1) xor APoly
      end else
      begin
        c := c shr 1;
      end;
    end;
    ACrc32SlicingByNTable^[0,i] := c;
  end;
  for i := 0 to 255 do
  begin
    c := ACrc32SlicingByNTable^[0,i];
    for n := 1 to High(ACrc32SlicingByNTable^) do
    begin
      c := (c shr 8) xor ACrc32SlicingByNTable^[0,byte(c)];
      ACrc32SlicingByNTable^[n,i] := c;
    end;
  end;
end;

function CalcCrc32IeeeBuf(const B; const Size: Crc32NativeUInt; const InitialValue: Cardinal = cCrc32IeeeInit): Cardinal;
begin
  Result := crc32_slicing(B, Size, InitialValue, FCrc32IeeeTable);
end;

function CalcCrc32CastagnoliBuf(const buf; const len: Crc32NativeUInt; crc: Cardinal = cCrc32CastagnoliInit): Cardinal;
begin
  Result := not crc32_slicing(buf, len, not crc, FCrc32CastagnoliTable);
end;

procedure Err;
begin
  WriteLn('CRC32 Test Error');
  Halt(1);
end;

procedure TestCRC;
var
  LQuickBrownFoxA: AnsiString;
  crc: Cardinal;
begin
  LQuickBrownFoxA := 'The quick brown fox jumps over the lazy dog';
  crc := CalcCrc32IeeeBuf(PAnsiChar(LQuickBrownFoxA)^, Length(LQuickBrownFoxA));
  if crc <> $BEB05CC6 then Err;
  crc := CalcCrc32CastagnoliBuf(PAnsiChar(LQuickBrownFoxA)^, Length(LQuickBrownFoxA));
  if crc <> $22620404 then Err;
  WriteLn('CRC Test passed');
  Halt(0);
end;

begin
  InitCrc32SlicingByNTable(FCrc32IeeeTable, cCrc32IeeePoly);
  InitCrc32SlicingByNTable(FCrc32CastagnoliTable, cCrc32CastagnoliPoly);
  TestCRC;
end.
