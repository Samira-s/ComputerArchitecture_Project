@echo off
set xv_path=C:\\Xilinx\\Vivado\\2016.4\\bin
call %xv_path%/xelab  -wto b48bff800b6643cebdca694b7ccc533b -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot CPU_Test_func_synth xil_defaultlib.CPU_Test -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
