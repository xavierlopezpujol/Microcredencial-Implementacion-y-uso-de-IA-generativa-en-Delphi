unit SystemInfo;

interface

uses
  Windows, SysUtils, Classes, Registry;

type
  TSystemInfo = record
    ComputerName: string;
    UserName: string;
    OSVersion: string;
    ProcessorName: string;
    ProcessorArchitecture: string;
    NumberOfProcessors: Integer;
    TotalPhysicalMemory: Int64;
    AvailablePhysicalMemory: Int64;
    TotalVirtualMemory: Int64;
    AvailableVirtualMemory: Int64;
    SystemDrive: string;
    SystemDriveTotalSpace: Int64;
    SystemDriveFreeSpace: Int64;
    TempDirectory: string;
    WindowsDirectory: string;
    SystemDirectory: string;
  end;

function GetSystemInformation: TSystemInfo;
function FormatBytes(Bytes: Int64): string;
function GetProcessorName: string;
function GetWindowsVersion: string;

function ShowSystemInfo:string;

implementation

function FormatBytes(Bytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
  TB = GB * Int64(1024);
begin
  if Bytes >= TB then
    Result := Format('%.2f TB', [Bytes / TB])
  else if Bytes >= GB then
    Result := Format('%.2f GB', [Bytes / GB])
  else if Bytes >= MB then
    Result := Format('%.2f MB', [Bytes / MB])
  else if Bytes >= KB then
    Result := Format('%.2f KB', [Bytes / KB])
  else
    Result := Format('%d bytes', [Bytes]);
end;

function GetProcessorName: string;
var
  Registry: TRegistry;
begin
  Result := 'Desconocido';
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    if Registry.OpenKey('HARDWARE\DESCRIPTION\System\CentralProcessor\0', False) then
    begin
      if Registry.ValueExists('ProcessorNameString') then
        Result := Trim(Registry.ReadString('ProcessorNameString'))
      else if Registry.ValueExists('Identifier') then
        Result := Registry.ReadString('Identifier');
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

function GetWindowsVersion: string;
var
  OSVersionInfo: TOSVersionInfo;
  Registry: TRegistry;
  ProductName: string;
begin
  Result := 'Windows';

  // Intentar obtener el nombre del producto desde el registro
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    if Registry.OpenKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion', False) then
    begin
      if Registry.ValueExists('ProductName') then
        ProductName := Registry.ReadString('ProductName');
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;

  if ProductName <> '' then
    Result := ProductName
  else
  begin
    // Método alternativo usando TOSVersionInfo
    FillChar(OSVersionInfo, SizeOf(OSVersionInfo), 0);
    OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
    if GetVersionEx(OSVersionInfo) then
    begin
      Result := Format('Windows %d.%d Build %d',
        [OSVersionInfo.dwMajorVersion, OSVersionInfo.dwMinorVersion, OSVersionInfo.dwBuildNumber]);
      if OSVersionInfo.szCSDVersion <> '' then
        Result := Result + ' ' + string(OSVersionInfo.szCSDVersion);
    end;
  end;
end;

function GetSystemInformation: TSystemInfo;
var
  SysInfo: SYSTEM_INFO;
  MemStatus: MEMORYSTATUSEX;
  Buffer: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
  FreeBytes, TotalBytes: Int64;
  SystemDrive: string;
begin
  // Obtener información del sistema
  GetSystemInfo(SysInfo);

  // Obtener información de memoria
  MemStatus.dwLength := SizeOf(MEMORYSTATUSEX);
  GlobalMemoryStatusEx(MemStatus);

  // Nombre del equipo
  Size := SizeOf(Buffer);
  if GetComputerName(Buffer, Size) then
    Result.ComputerName := string(Buffer)
  else
    Result.ComputerName := 'Desconocido';

  // Nombre del usuario
  Size := SizeOf(Buffer);
  if GetUserName(Buffer, Size) then
    Result.UserName := string(Buffer)
  else
    Result.UserName := 'Desconocido';

  // Información básica
  Result.OSVersion := GetWindowsVersion;
  Result.ProcessorName := GetProcessorName;
  Result.NumberOfProcessors := SysInfo.dwNumberOfProcessors;

  // Arquitectura del procesador
  case SysInfo.wProcessorArchitecture of
    PROCESSOR_ARCHITECTURE_AMD64: Result.ProcessorArchitecture := 'x64';
    PROCESSOR_ARCHITECTURE_IA64: Result.ProcessorArchitecture := 'IA64';
    PROCESSOR_ARCHITECTURE_INTEL: Result.ProcessorArchitecture := 'x86';
    else Result.ProcessorArchitecture := 'Desconocido';
  end;

  // Información de memoria
  Result.TotalPhysicalMemory := MemStatus.ullTotalPhys;
  Result.AvailablePhysicalMemory := MemStatus.ullAvailPhys;
  Result.TotalVirtualMemory := MemStatus.ullTotalVirtual;
  Result.AvailableVirtualMemory := MemStatus.ullAvailVirtual;

  // Información de disco del sistema
  SystemDrive := Copy(GetEnvironmentVariable('SystemDrive'), 1, 1) + ':\';
  Result.SystemDrive := SystemDrive;

  if GetDiskFreeSpaceEx(PChar(SystemDrive), FreeBytes, TotalBytes, nil) then
  begin
    Result.SystemDriveFreeSpace := FreeBytes;
    Result.SystemDriveTotalSpace := TotalBytes;
  end
  else
  begin
    Result.SystemDriveFreeSpace := 0;
    Result.SystemDriveTotalSpace := 0;
  end;

  // Directorios del sistema
  Result.TempDirectory := GetEnvironmentVariable('TEMP');
  Result.WindowsDirectory := GetEnvironmentVariable('windir');
  Result.SystemDirectory := GetEnvironmentVariable('SystemRoot') + '\System32';
end;

// Función de ejemplo para mostrar toda la información
function ShowSystemInfo:string;
var
  SysInfo: TSystemInfo;
  Info: TStringList;
begin
  SysInfo := GetSystemInformation;
  Info := TStringList.Create;
  try
    Info.Add('=== INFORMACIÓN DEL SISTEMA ===');
    Info.Add('');
    Info.Add('Equipo: ' + SysInfo.ComputerName);
    Info.Add('Usuario: ' + SysInfo.UserName);
    Info.Add('Sistema Operativo: ' + SysInfo.OSVersion);
    Info.Add('');
    Info.Add('=== PROCESADOR ===');
    Info.Add('Nombre: ' + SysInfo.ProcessorName);
    Info.Add('Arquitectura: ' + SysInfo.ProcessorArchitecture);
    Info.Add('Número de procesadores: ' + IntToStr(SysInfo.NumberOfProcessors));
    Info.Add('');
    Info.Add('=== MEMORIA ===');
    Info.Add('Memoria física total: ' + FormatBytes(SysInfo.TotalPhysicalMemory));
    Info.Add('Memoria física disponible: ' + FormatBytes(SysInfo.AvailablePhysicalMemory));
    Info.Add('Memoria virtual total: ' + FormatBytes(SysInfo.TotalVirtualMemory));
    Info.Add('Memoria virtual disponible: ' + FormatBytes(SysInfo.AvailableVirtualMemory));
    Info.Add('');
    Info.Add('=== ALMACENAMIENTO ===');
    Info.Add('Unidad del sistema: ' + SysInfo.SystemDrive);
    Info.Add('Espacio total: ' + FormatBytes(SysInfo.SystemDriveTotalSpace));
    Info.Add('Espacio libre: ' + FormatBytes(SysInfo.SystemDriveFreeSpace));
    Info.Add('Espacio usado: ' + FormatBytes(SysInfo.SystemDriveTotalSpace - SysInfo.SystemDriveFreeSpace));
    Info.Add('');
    Info.Add('=== DIRECTORIOS ===');
    Info.Add('Directorio temporal: ' + SysInfo.TempDirectory);
    Info.Add('Directorio de Windows: ' + SysInfo.WindowsDirectory);
    Info.Add('Directorio del sistema: ' + SysInfo.SystemDirectory);

    // Aquí puedes mostrar la información como prefieras
    // Por ejemplo, en un memo o guardar en archivo
    Result := Info.Text;

  finally
    Info.Free;
  end;
end;

end.
