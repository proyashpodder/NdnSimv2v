import os,sys
import time

if 'SUMO_HOME' in os.environ:
    tools = os.path.join(os.environ['SUMO_HOME'], 'tools')
    sys.path.append(tools)
else:
    sys.exit("please declare environment variable 'SUMO_HOME'")

import traci
import traci.constants as tc

sumoCmd = ["sumo-gui", "-c", "ped_crossing/run.sumocfg", "--start"]
traci.start(sumoCmd)
step = 0
time.sleep(5)
while step < 100:
    traci.simulationStep()
    vehicles=traci.vehicle.getIDList()
    pedestrians = traci.person.getIDList()
    for vehicle in vehicles:
        speed = round(traci.vehicle.getSpeed(vehicle))
        pos = traci.vehicle.getPosition(vehicle)
        angle = traci.vehicle.getAngle(vehicle)
        traci.vehicle.setSpeedMode(vehicle,30)
    for pedestrian in pedestrians:
        speed = round(traci.person.getSpeed(pedestrian))
        print(speed)

    step = step + 1

traci.close()
