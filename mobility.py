# use the command "python3 mobility.py" to run the scneario. No parameter needed

import os, sys
if 'SUMO_HOME' in os.environ:
  tools = os.path.join(os.environ['SUMO_HOME'], 'tools')
  sys.path.append(tools)
else:
  sys.exit("please declare environment variable 'SUMO_HOME'")

import traci
import traci.constants as tc
import time
import re

#traci.start(["sumo-gui", "-c", "intersection.sumocfg"])
sumoCmd = ["sumo", "-c", "sumo/intersection/intersection.sumocfg", "--start"]
traci.start(sumoCmd)

print("Starting SUMO")
j = 0

while(j<60):
  f = open("ns2-trace3.tcl","w+")
  dict = {}
  time.sleep(0.5)
  traci.simulationStep()
  vehicles=traci.vehicle.getIDList();
  for i in range(0,len(vehicles)):
    speed = round(traci.vehicle.getSpeed(vehicles[i]))
    pos = traci.vehicle.getPosition(vehicles[i])
    x = round(pos[0],1)
    y = round(pos[1],1)
    angle = traci.vehicle.getAngle(vehicles[i])
    dict[i] = vehicles[i]
    f.write('$ns_ at '+str(j)+' "$node_('+str(i)+') setdest '+str(x)+' '+str(y)+' '+str(speed)+' '+str(angle)+'"\n')
  j= j+1
  f.close()
  num_nodes = sum(1 for line in open('ns2-trace3.tcl'))
  print(num_nodes)
  os.system('./waf --run="mobility --traceFile=ns2-trace3.tcl --nodeNum='+ str(num_nodes-1)+ ' --logFile=ab.log"')
traci.close()      
