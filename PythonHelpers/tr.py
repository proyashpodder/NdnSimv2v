import os
import subprocess

#subprocess.call("ls")
#subprocess.call("ls")
#subprocess.call(['script','output.txt'])
#subprocess.call(['NS_LOG=ndn.Consumer:ndn.Producer:ndn-cxx.nfd.DirectedGeocastStrategy:LteSlOutOfCovrg','./waf','--run=v2vscene'])
os.system('NS_LOG=ndn.Consumer:ndn.Producer:ndn-cxx.nfd.DirectedGeocastStrategy:LteSlOutOfCovrg ./waf --run=v2vscene > output.txt')
#subprocess.call("exit")
records = [0.0] * 10
count = [0] * 10
fileName = 'output.txt'
with open(fileName,'r') as stream:
    for line in stream:
        #print(line)
        if 'ReceivedInterest:' in line:
            #print(line)
            if(line[14] != ' '):
                nodeID = int(line[14])
                time= (float(line[3:10]) * 0.0000001)
                #time = (int)timeString
                print(nodeID)
                print(time)
            else:
                nodeID = int(line[15])
                time= (float(line[4:11]) * 0.0000001)
            if(nodeID !=1):
                records[nodeID] += time
                count[nodeID] = count[nodeID] + 1

    for (i,j) in zip(records,count):
        if( j != 0 ):
            print(i/j)
            #print(j)
