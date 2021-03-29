import os,sys
import time

#for tmin in [0.02,0.08,0.12,0.16,0.2]:
    #for tmax in [0.2,0.25,0.3,0.35,0.4,0.45]:
        #path = 'python3 scenarios/dynamic_pedestrian.py --dis=100 --duration=61 --tmin=' + str(tmin) + ' --tmax=' +str(tmax)
        #print(path)
        #os.system(path)
        
for run in range(1,6):
    path = 'python3 scenarios/dynamic_pedestrian.py --duration=61 --dis=100 --tminD=0.0001 --tmaxD=0.5 --run=' + str(run)
    #path = 'python3 scenarios/dynamic_pedestrian.py --duration=61 --tminD=0.0001 --tmaxD=0.5 --run=' + str(run)
    #path = 'python3 scenarios/dynamic_pedestrian.py --poi=four --duration=61 --tminD=0.0001 --tmaxD=0.5 --run=' + str(run)
    print(path)
    os.system(path)


