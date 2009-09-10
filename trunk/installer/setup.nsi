!define py2exeOutputDir 'dist'
!define exe 'videocity.exe'
!define icon '../www/favicon.ico'
!define compressor 'lzma'  ; one of 'zlib', 'bzip2', 'lzma'
!define onlyOneInstance

; Comment out the "SetCompress Off" line and uncomment
; the next line to enable compression. Startup times
; will be a little slower but the executable will be
; quite a bit smaller
!ifdef compressor
    SetCompressor ${compressor}
!else
    SetCompress Off
!endif

Name ${exe}
OutFile ${exe}
SilentInstall silent
!ifdef icon
    Icon ${icon}
!endif

; - - - - Allow only one installer instance - - - - 
!ifdef onlyOneInstance
Function .onInit
 System::Call "kernel32::CreateMutexA(i 0, i 0, t '$(^Name)') i .r0 ?e"
 Pop $0
 StrCmp $0 0 launch
  Abort
 launch:
FunctionEnd
!endif
; - - - - Allow only one installer instance - - - - 

Section
    InitPluginsDir
    SetOutPath '$PLUGINSDIR'
    File /r '${py2exeOutputDir}\*.*'
    SetOutPath '$EXEDIR'        ; uncomment this line to start the exe in the PLUGINSDIR
    nsExec::Exec $PLUGINSDIR\${exe}
SectionEnd
