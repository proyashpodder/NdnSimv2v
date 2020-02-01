import os
import csv
import subprocess
rng = 1
while rng < 6:
#count = 2.000
#os.system('rm out575.txt')
#os.system('rm outFile575.csv')
    distance = 300
    timeList  = [0] * 10
    inList = [0] * 10
    dataList = [0] * 10
    nodeNumber = 10;
    os.system("rm *.txt")
    csvFile = open('results/fixedmultihopnodenumber-'+str(rng)+'.csv', "a")
    csvWriter = csv.writer( csvFile )
    csvWriter.writerow(['nodenumber','timeTogetData'])

    while nodeNumber < 101:
        #count = 2.000
        #while count < 2.1:
        path = 'NS_GLOBAL_VALUE="RngRun='+str(rng)+'" ./waf --run="multihops-nodenumber --distance='+str(distance)+' --nodeNumber='+str(nodeNumber)+'">>temp/'+str(nodeNumber)+'.txt'
        print(path)
        os.system(path)
            #count+= 0.05
        with open('temp/'+str(nodeNumber)+'.txt','r') as stream:
            count = 0
            time = 0
            for line in stream:
                if 'Interest' in line:
                    inTime = float(line[0:6])
                    inToken = int(line[21])
                    inList[inToken] = inTime
                    print("intime: "+str(inTime))
                if 'Data' in line:
                    dataTime = float(line[0:6])
                    dataToken = int(line[17])
                    print("datatime: "+str(dataToken))
                    dataList[dataToken] = dataTime
                    #diff = inTime - outTime
                    #print(diff)
                    #csvWriter.writerow( [outTime, inTime,diff] )
            for i in range (0,10):
                print(inList[i])
                print(dataList[i])
                if(inList[i] != 0 and dataList[i]!= 0):
                    time += dataList[i] - inList[i]
                    count += 1
                    print(timeList[i])
            avarage = time / count;
            csvWriter.writerow( [nodeNumber,avarage] )
        nodeNumber = nodeNumber + 10;
    rng = rng +1




