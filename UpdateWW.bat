@echo off
cd /d C:\Users\spraydata
"C:\Program Files\MATLAB\R2022a\bin\matlab.exe" -noopengl -r "try; run('C:\Users\spraydata\Documents\GitHub\MBARIWireWalker\UpdateWWData.m'); catch; end; exit;"