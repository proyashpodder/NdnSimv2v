Each .cc file in this directory will be treated as a separate scenario 
(i.e., each .cc should contain their own main function).  Each scenario will
be linked together with all extensions, placed in ../extensions/ folder.

to run the mobility.cpp scenario, use the following command:
 "./waf --run="mobility --traceFile=trace.tcl --nodeNum=59 --duration=50.00 --logFile=1.log""

