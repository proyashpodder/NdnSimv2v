import os
import csv

csvFile = open('results/TxPower-packetLoss.csv',"a")
csvWriter=csv.writer(csvFile)
csvWriter.writerow(['distance','TxPower','value'])

for PscchTxPower in range (1,25):
    for distance in range (10,201,10):
        path='./waf --run="packetLoss --nodeNumber=2 --distance='+str(distance)+' --PscchTxPower='+str(PscchTxPower)+'">>temp/pl-'+str(distance)+str(PscchTxPower)+'.txt'
        print(path)
        os.system(path)
        value = 0
        with open('temp/pl-'+str(distance)+str(PscchTxPower)+'.txt','r') as stream:
            for line in stream:
                if 'Data' in line:
                    value = 1;
            csvWriter.writerow([distance,PscchTxPower,value])
