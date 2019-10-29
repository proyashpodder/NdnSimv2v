import os
import csv
import subprocess

#count = 2.000
#os.system('rm out575.txt')
#os.system('rm outFile575.csv')
distance = 525
while distance < 600:
    count = 2.000
    while count < 2.1:
        path = './waf --run="testv2v --count='+str(count)+' --distance='+str(distance)+'">>'+str(distance)+'.txt'
        print(path)
        os.system(path)
        count+= 0.05
    with open(str(distance)+'.txt','r') as stream:
        outTime = 0.0
        inTime = 0.0
        csvFile = open(str(distance)+'.csv', "a")
        csvWriter = csv.writer( csvFile )
        for line in  stream:
            if 'out,' in line:
                outTime = float(line[11:17])
                print("outtime: "+str(outTime))
            if 'in,' in line:
                inTime = float(line[10:16])
                print("intime: "+str(inTime))
                diff = inTime - outTime
                print(diff)
                csvWriter.writerow( [outTime, inTime,diff] )
    distance = distance + 25;

