import os
import csv
import subprocess

#count = 2.000
#os.system('rm out575.txt')
#os.system('rm outFile575.csv')
distance = 25
timeList  = [0] * 10
inList = [0] * 10
dataList = [0] * 10
while distance < 175:
    #count = 2.000
    #while count < 2.1:
    path = './waf --run="1hop --distance='+str(distance)+'">>'+str(distance)+'.txt'
    print(path)
    os.system(path)
        #count+= 0.05
    with open(str(distance)+'.txt','r') as stream:
        csvFile = open('results/new1hop-'+str(distance)+'.csv', "a")
        csvWriter = csv.writer( csvFile )
        csvWriter.writerow(['interestTime','dataTime','timeTogetData'])
        for line in stream:
            if 'Interest' in line:
                inTime = float(line[0:6])
                inToken = int(line[21])
                inList[inToken] = inTime
                print("intime: "+str(inTime))
            if 'Data' in line:
                dataTime = float(line[0:6])
                dataToken = int(line[17])
                print("outtime: "+str(dataToken))
                dataList[dataToken] = dataTime
                #diff = inTime - outTime
                #print(diff)
                #csvWriter.writerow( [outTime, inTime,diff] )
        for i in range (0,10):
            print(inList[i])
            print(dataList[i])
            if(inList[i] != 0 and dataList[i]!= 0):
                timeList[i] = dataList[i] - inList[i]
                print(timeList[i])
                csvWriter.writerow( [inList[i], dataList[i],timeList[i]] )
    distance = distance + 25;


