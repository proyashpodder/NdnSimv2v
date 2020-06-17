import os
import csv
csvFile = open('results/dis-freq-packetLoss.csv',"a")
csvWriter= csv.writer(csvFile)
csvWriter.writerow(['distance','frequency','percentage'])
for frequency in range (1,21):
    for distance in range (10,201,10):
        path='./waf --run="packetLoss --nodeNumber=2 --distance='+str(distance)+' --frequency='+str(frequency)+'">>temp/pl-'+str(distance)+str(frequency)+'.txt'
        print(path)
        os.system(path)
        
        with open('temp/pl-'+str(distance)+str(frequency)+'.txt','r') as stream:
            count = 0
            for line in stream:
                if 'Data' in line:
                    count = count + 1
            percentage = (count/frequency) * 100
            csvWriter.writerow([distance,frequency,percentage])
        
