unit FibonacciUnit;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TFibonacciArray = TArray<Int64>;

// Función que retorna un array con la serie de Fibonacci hasta N términos
function CalcularFibonacci(N: Integer): TFibonacciArray;

// Función que retorna el N-ésimo número de Fibonacci
function FibonacciNesimo(N: Integer): Int64;

// Procedimiento para mostrar la serie completa
procedure MostrarSerieFibonacci(N: Integer);

implementation

function CalcularFibonacci(N: Integer): TFibonacciArray;
var
  i: Integer;
begin
  if N <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Result, N);

  if N >= 1 then
    Result[0] := 0;

  if N >= 2 then
    Result[1] := 1;

  for i := 2 to N - 1 do
    Result[i] := Result[i-1] + Result[i-2];
end;

function FibonacciNesimo(N: Integer): Int64;
var
  a, b, temp: Int64;
  i: Integer;
begin
  if N <= 0 then
  begin
    Result := 0;
    Exit;
  end;

  if N = 1 then
  begin
    Result := 0;
    Exit;
  end;

  if N = 2 then
  begin
    Result := 1;
    Exit;
  end;

  a := 0;  // F(0)
  b := 1;  // F(1)

  for i := 3 to N do
  begin
    temp := a + b;
    a := b;
    b := temp;
  end;

  Result := b;
end;

procedure MostrarSerieFibonacci(N: Integer);
var
  serie: TFibonacciArray;
  i: Integer;
  output: string;
begin
  serie := CalcularFibonacci(N);

  if Length(serie) = 0 then
  begin
    Writeln('N debe ser mayor que 0');
    Exit;
  end;

  output := 'Serie de Fibonacci (' + IntToStr(N) + ' términos): ';

  for i := 0 to Length(serie) - 1 do
  begin
    output := output + IntToStr(serie[i]);
    if i < Length(serie) - 1 then
      output := output + ', ';
  end;

  Writeln(output);
end;

end.

