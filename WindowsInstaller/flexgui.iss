;============================================================================
; Installer for FlexGui
; Created with Inno Setup 6.0.3.
; (C) 2019-2020 Jac Goudsmit
;
; Licensed under the MIT license.
; See the file License.txt for details.
;============================================================================


;============================================================================
; The following code is meant to read the version.tcl file at compile time
; and convert it to an INI file which is used to generate the version number.

; Global variables
#define FileHandle
#define FileLine
#define IniFile = SourcePath + "tmp.ini"
#define IniSection = "Vars"

; Function to get the text in front of the first space of a string
#define BeforeSpace(Str S) \
  Local[0] = Pos(" ", S) , \
  (Local[0] ? Copy(S, 1, Local[0] - 1) : "")

; Function to get the text behind the first space of a string
#define AfterSpace(Str S) \
  Local[0] = Pos(" ", S) , \
  (Local[0] ? Copy(S, Local[0] + 1) : "")

; Function to get the text that follows a "set" Tcl command.
; Returns a blank string if the text doesn't start with "set".
#define RemoveSetCommand(Str S) \
  (Copy(S, 1, 4) == "set " ? Copy(S, 5) : "")

; Subroutine to read a line from the .tcl file and, if it's a "set" command,
; store it in an INI file.
#sub ProcessLine
  #define FileLine = RemoveSetCommand(FileRead(FileHandle))
  #if Len(FileLine)
    #define TclVar = BeforeSpace(FileLine)
    #define TclVal = AfterSpace(FileLine)
    #expr WriteIni(IniFile, IniSection, TclVar, TclVal)
    #pragma message TclVar + "=" + TclVal
  #endif
#endsub

; Preprocessor code to parse the version.tcl file at compile time
#for {FileHandle = FileOpen("..\flexgui\src\version.tcl"); \
  FileHandle && !FileEof(FileHandle); ""} \
  ProcessLine
#if FileHandle
  #expr FileClose(FileHandle)
#endif

; Shortcut to get a converted Tcl variable from the INI file
#define GetTcl(Str S) \
  ReadIni(IniFile, IniSection, S)

;============================================================================

; The Application ID is used in the registry to recognize existing
; installations. It's possible to use a name here but we use a GUID to
; prevent clashes with other applications. This should NEVER be changed.
#define APPID       "30EA9831-3B35-41B5-8D82-CE51796D014E"

; License file to use
;#define LICENSE     "License.txt"
#define LICENSE

; Source directory
; The file you are reading was designed to get its sources from this
; location.
#define SRCDIR      "..\flexgui"

; EXE file to extract version information from
#define EXE         "flexgui.exe"

; URL for more information
#define URL         "https://github.com/totalspectrum/flexgui"

; Base directory to use for installation
#define BASEDIR     "Total Spectrum Software"

; The easiest way to set the following information on the installer with
; InnoSetup is to extract it from an executable file. Unfortunately the
; product name and version number on the Flexgui executable aren't correct
; because that .exe is really just the Tcl/Tk runtime.
; In case this changes in the future, the code to extract the data is
; commented out below.
; For now, we get the version from the version.tcl instead, at compile time,
; using the InnoSetup preprocessor.
;#define PRODNAME    GetStringFileInfo(EXE, PRODUCT_NAME)
;#define VERSION     GetStringFileInfo(EXE, FILE_VERSION)
#define PRODNAME    "FlexGUI for Windows"
#define VERSION     GetTcl("spin2gui_version_major") + "." + GetTcl("spin2gui_version_minor") + "." + GetTcl("spin2gui_version_rev") + GetTcl("spin2gui_beta")
#define COMPANY     GetFileCompany(EXE)
#define COPYRIGHT   GetFileCopyright(EXE)

; Short product name for use in directories etc.
#define SHORTPROD   "FlexGUI"

; Default directory to store projects
#define DATADIR     "{commondocs}\"+SHORTPROD

[Setup]
AppId={#APPID}
AppName={#PRODNAME}
AppVerName={#PRODNAME} {#VERSION}
AppVersion={#VERSION}
VersionInfoVersion={#VERSION}
AppCopyright={#COPYRIGHT}
SourceDir={#SRCDIR}
OutputDir=.
OutputBaseFilename={#SHORTPROD}Setup-{#VERSION}
AppPublisher={#COMPANY}
AppPublisherURL={#URL}
AppSupportURL={#URL}
AppUpdatesURL={#URL}
DefaultDirName={commonpf}\{#BASEDIR}\{#PRODNAME}
; Set Windows 7 as minimum required version
MinVersion=0,6.1.7600
DisableDirPage=yes
DefaultGroupName={#PRODNAME}
DisableProgramGroupPage=yes
DisableReadyPage=yes
LicenseFile={#LICENSE}
Compression=lzma/ultra
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#PRODNAME}
PrivilegesRequired=admin

[Components]
Name: "samples";        Description: "Install Sample Code in {#DATADIR} folder"; Types: full custom

[InstallDelete]
; Any files that were ever in the Files section but are no longer in use,
; should be moved to this section.
; example:
;Type: files; Name: "{app}\nolongerneeded.exe";

[Dirs]
; Create the default directory to store projects
Name:     "{#DATADIR}"

[Files]
; IMPORTANT: If any file in the distribution is no longer necessary,
; it should not only be removed from this section, but it should also
; be added to the InstallDelete section.

Source:   "flexgui.exe";                DestDir: "{app}";                             Flags: ignoreversion;
Source:   "flexgui.tcl";                DestDir: "{app}";
 Source:   "src\*";                      DestDir: "{app}\src";                         Flags: ignoreversion recursesubdirs;
Source:   "License.txt";                DestDir: "{app}";
Source:   "README.md";                  DestDir: "{app}";

Source:   "bin\fastspin.exe";           DestDir: "{app}\bin";                         Flags: ignoreversion
Source:   "bin\loadp2.exe";             DestDir: "{app}\bin";                         Flags: ignoreversion; 
Source:   "bin\proploader.exe";         DestDir: "{app}\bin";                         Flags: ignoreversion; 

 Source:   "board\*";                    DestDir: "{app}\board";                       Flags: ignoreversion recursesubdirs; 

 Source:   "doc\*";                      DestDir: "{app}\doc";                         Flags: ignoreversion recursesubdirs;

 Source:   "include\*";                  DestDir: "{app}\include";                     Flags: ignoreversion recursesubdirs;

; Samples will not be erased at uninstall time, in case the user made changes
 Source:   "samples\*";                  DestDir: "{#DATADIR}\samples";                Flags: ignoreversion recursesubdirs uninsneveruninstall; Components: samples

[Icons]
Name:     "{group}\{#PRODNAME}";        Filename: "{app}\flexgui.exe"; WorkingDir: "{#DATADIR}";

[UninstallDelete]
; Files that should go in here are files that weren't installed by the
; installer, but need to be deleted to at uninstall time.

Type: files; Name: "{%USERPROFILE}\.flexgui.config"

[Run]
Filename: {app}\flexgui.exe;            Description: "Launch {#SHORTPROD} after installation"; Flags: nowait postinstall skipifsilent

