;============================================================================
; Installer for FlexGui
; Created with Inno Setup 6.0.3.
; (C) 2019 Jac Goudsmit
;
; Licensed under the MIT license.
; See the file License.txt for details.
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

; Extract information from the exe file
; Unfortunately the product name and version get assimilated by Tcl/Tk
;#define PRODNAME    GetStringFileInfo(EXE, PRODUCT_NAME)
;#define VERSION     GetStringFileInfo(EXE, FILE_VERSION)
#define PRODNAME    "FlexGUI for Windows"
#define VERSION     "4.1.2"
#define COMPANY     GetFileCompany(EXE)
#define COPYRIGHT   GetFileCopyright(EXE)

; Short product name for use in directories etc.
#define SHORTPROD   "FlexGUI"

; Default directory to store projects
; We must use double braces here, because the values should be expanded
; when the macro is used; not here.
#define DATADIR     "{userdocs}\"+SHORTPROD

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
Name: "samples";        Description: "Install Sample Code (in {#SHORTPROD} under your Documents)"; Types: full custom

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

Source:   "board\P2ES_flashloader.bin"; DestDir: "{app}\board";                       Flags: ignoreversion; 

Source:   "doc\basic_tutorial\*";       DestDir: "{app}\doc\basic_tutorial";
Source:   "doc\basic.md";               DestDir: "{app}\doc";
Source:   "doc\basic.pdf";              DestDir: "{app}\doc";
Source:   "doc\basic_tutorial.md";      DestDir: "{app}\doc";
Source:   "doc\c.md";                   DestDir: "{app}\doc";
Source:   "doc\c.pdf";                  DestDir: "{app}\doc";
Source:   "doc\Fastspin.pdf";           DestDir: "{app}\doc";
Source:   "doc\help.txt";               DestDir: "{app}\doc";
Source:   "doc\Optimization.md";        DestDir: "{app}\doc";
Source:   "doc\pasm_code.md";           DestDir: "{app}\doc";
Source:   "doc\spin.md";                DestDir: "{app}\doc";
Source:   "doc\spin.pdf";               DestDir: "{app}\doc";
Source:   "doc\SpinPasmIntegration.md"; DestDir: "{app}\doc";
Source:   "doc\TODO.md";                DestDir: "{app}\doc";

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
