import os,sys
import time
import math

if 'SUMO_HOME' in os.environ:
    tools = os.path.join(os.environ['SUMO_HOME'], 'tools')
    sys.path.append(tools)
else:
    sys.exit("please declare environment variable 'SUMO_HOME'")

import traci
import traci.constants as tc

sumoCmd = ["sumo-gui", "-c", "sumo/intersection.sumocfg", "--start"]
traci.start(sumoCmd)
step = 0
time.sleep(5)

def findDistance(x1, y1, x2, y2):
    return math.sqrt(math.pow((x1-x2),2) + math.pow((y1-y2),2))
    
while step < 100:
    traci.simulationStep()
    vehicles=traci.vehicle.getIDList()
    pedestrians = traci.person.getIDList()
    for vehicle in vehicles:
        speed = round(traci.vehicle.getSpeed(vehicle))
        pos = traci.vehicle.getPosition(vehicle)
        angle = traci.vehicle.getAngle(vehicle)
        distanceTravelled = traci.vehicle.getDistance(vehicle)
        
        if (findDistance(pos[0],pos[1],500.0,500.0) < 50):
            tls = traci.vehicle.getNextTLS(vehicle)
            leader = traci.vehicle.getLeader(vehicle)
            
            
            #traffic_state = tls[0][3]
            #print(vehicle)
            #print(leader)
            traci.vehicle.setSpeedMode(vehicle,30)
            
            if(not leader):
                traci.vehicle.setSpeed(vehicle,10)
            else:
                leader_distance = leader[1]
                if(leader_distance > 40.0):
                    traci.vehicle.setSpeed(vehicle,10)
                else:
                    traci.vehicle.setSpeed(vehicle,max(leader_distance - 20, 0))

            #if(len(tls) > 0):
                #traffic_state = tls[0][3]
                #if(traffic_state == 'G'):
                    #traci.vehicle.setSpeedMode(vehicle,30)
                    #traci.vehicle.setSpeed(vehicle,20)
        #print(speed)
        
        if(distanceTravelled > 550):
            traci.vehicle.setSpeedMode(vehicle,31)
            speedWithoutTraci = traci.vehicle.getSpeedWithoutTraCI(vehicle)
            traci.vehicle.setSpeed(vehicle,speedWithoutTraci)
            #traci.vehicle.setSpeed(vehicle,
        #if(step == 60):
            #print(traci.vehicle.getSpeedMode(vehicle))
            #print(traci.vehicle.getSpeed(vehicle))
    #for pedestrian in pedestrians:
        #speed = round(traci.person.getSpeed(pedestrian))
        

    step = step + 1

traci.close()

