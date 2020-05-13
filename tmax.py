import os
import csv
import subprocess
tmax=0.1
while tmax < 0.7:
      path='./waf --run="multihops-nodenumber --distance=200 --nodeNumber=50 --tmax='+str(tmax)+'"'
      os.system(path)
      print(path)
      tmax = tmax+0.1
