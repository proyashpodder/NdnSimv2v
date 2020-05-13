import os
import csv
import subprocess

#count = 2.000
#os.system('rm out575.txt')
#os.system('rm outFile575.csv')

rng = 1
#os.system('rm results/datahop.csv')
os.system("rm temp/*.txt")
while rng < 2:
    distance = 100
    tmax=0.2
    timeList  = [0] * 10
    inList = [0] * 10
    dataList = [0] * 10
    hopList = [0] * 10
    csvFile = open('results/data-retrieval-distance-rng'+str(rng)+'.csv', "w")
    csvWriter = csv.writer( csvFile )
    csvWriter.writerow(['distance','timeTogetData','hopCount'])
    while distance < 1001:
        #count = 2.001
        #while count < 2.1:
        path = 'NS_GLOBAL_VALUE="RngRun='+str(rng)+'" ./waf --run="multihops-nodenumber --distance='+str(distance)+' --tmax='+str(tmax)+'">>temp/'+str(rng)+str(distance)+'.txt'
        print(path)
        os.system(path)
            #count+= 0.05
        with open('temp/'+str(rng)+str(distance)+'.txt','r') as stream:
            count = 0
            time = 0
            hop = 0
            for line in stream:
                if 'Interest' in line:
                    inTime = float(line[0:6])
                    inToken = int(line[21])
                    inList[inToken] = inTime
                    print("intime: "+str(inTime))
                if 'Data' in line:
                    dataTime = float(line[0:6])
                    #print(line)
                    dataToken = int(line[17])
                    print("outtime: "+str(dataToken))
                    dataList[dataToken] = dataTime
                    #diff = inTime - outTime
                    #print(diff)
                    #csvWriter.writerow( [outTime, inTime,diff] )
                if 'Hop' in line:
                    hopCount = int(line[0:1])
                    hopToken = int(line[16])
                    hopList[hopToken] = hopCount
                    print("hop count: "+str(hopCount))
                    
            for i in range (0,10):
                print(inList[i])
                print(dataList[i])
                if(inList[i] != 0 and dataList[i]!= 0):
                    time += dataList[i] - inList[i]
                    hop +=hopList[i]
                    count += 1
                    print(timeList[i])
            avarage = time / count
            hopAvrg = round(hop/ count)
            csvWriter.writerow( [distance,avarage,hopAvrg] )
        distance = distance + 50
    rng=rng+1



