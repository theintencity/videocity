set PYTHONPATH=..\..\p2p-sip\src;..\..\rtmplite;..\python;.
setup.py py2exe
"\Program Files\NSIS\makensis.exe" setup.nsi
cd dist
"\Program Files\7-Zip\7z.exe" a -tzip ..\videocity-1.1-win32.zip *
