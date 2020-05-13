import os
import subprocess

distance = 180
pssch = 23

while pssch > 0:
    while distance > 0:
        path = './waf --run="txpower --nodeNumber=2 --distance='+str(distance)+' --pssch='+str(pssch)+'">>'+str(pssch)+'.txt'
        print(path)
        os.system(path)
        distance-=10
    pssch-=2
    distance=180
