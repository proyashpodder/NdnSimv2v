
import os,sys

if 'SUMO_HOME' in os.environ:
    tools = os.path.join(os.environ['SUMO_HOME'], 'tools')
    sys.path.append(tools)
else:
    sys.exit("please declare environment variable 'SUMO_HOME'")

import traci
import traci.constants as tc

sumoCmd = ["sumo-gui", "-c", "intersection.sumocfg"]
traci.start(sumoCmd)

#traci.simulationStep(200)
#v = traci.simulation.getLoadedIDList()
#print(v)
    #traci.vehicle.setSpeedMode(v,0)
    #traci.vehicle.setMinGap(v,0)
traci.junction.subscribeContext('0', tc.CMD_GET_VEHICLE_VARIABLE, 14, [tc.VAR_POSITION, tc.VAR_SPEED, tc.VAR_DEPARTED_VEHICLES_NUMBER])
#l = traci.junction.getContextSubscriptionResults('0')


for k in range (0,200,1):
    traci.simulationStep(k)
    vehicles=traci.vehicle.getIDList()
    persons = traci.person.getIDList()
    traci.junction.subscribe('0')
    #print(traci.junction.getSubscriptionResults('0'))
    #print(traci.junction.getIDCount())
    #traci.junction.subscribeContext('0',vehicles,20);
    #print(traci.junction.getContextSubscriptionResults('0'))
    l = traci.junction.getContextSubscriptionResults('0')
    #print(l)
    for i in range(0,len(vehicles)):
        traci.vehicle.setSpeedMode(vehicles[i],0)
        traci.vehicle.setMinGap(vehicles[i],0)
        if(traci.vehicle.getLaneID(vehicles[i]) == "1i_2" and k == 35):
            print("hola")
            traci.vehicle.slowDown(vehicles[i],5,5)
        speed = round(traci.vehicle.getSpeed(vehicles[i]))
        pos = traci.vehicle.getPosition(vehicles[i])
        x = round(pos[0],1)
        y = round(pos[1],1)
        angle = traci.vehicle.getAngle(vehicles[i])
        #print("AT "+str(k)+" position of vehicle " + str(vehicles[i]) + " is: " + str(pos) + " and speed is: "+ str(speed))
        #print("AT "+str(k)+" Lane ID is: "+ str(traci.vehicle.getLaneID(vehicles[i])))
traci.close()

