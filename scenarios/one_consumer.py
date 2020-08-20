import os,sys

if 'SUMO_HOME' in os.environ:
    tools = os.path.join(os.environ['SUMO_HOME'], 'tools')
    sys.path.append(tools)
    #sys.path.append(os.path.join(os.environ.get("SUMO_HOME"), 'tools'))
else:
    sys.exit("please declare environment variable 'SUMO_HOME'")
    
from lte_sidelink_base import *

import traci
import traci.constants as tc
import time
import re
import sumolib
import math
import csv

from ns.mobility import MobilityModel, ConstantVelocityMobilityModel

data_file = open('results/multiple_adjusted_speed_accel.csv', 'w')
csv_writer = csv.writer(data_file)
csv_writer.writerow(["Time","Speed","Acceleration", "X","Y"])

net = sumolib.net.readNet('sumo/intersection.net.xml')
sumoCmd = ["sumo", "-c", "sumo/intersection.sumocfg"]

traci.start(sumoCmd, label="dry-run") # whole run to estimate and created all nodes with out of bound position and 0 speeds
g_traciDryRun = traci.getConnection("dry-run")

traci.start(sumoCmd, label="step-by-step")
g_traciStepByStep = traci.getConnection("step-by-step")

g_names = {}
p_names = {}
vehicleList = []
prevList = []
nowList = []
posOutOfBound = Vector(0, 0, -2000)
departedCount = 0


def createAllVehicles(simTime):
    g_traciDryRun.simulationStep(simTime)
    #vehicleList = g_traciDryRun.simulation.getLoadedIDList()
    for vehicle in g_traciDryRun.simulation.getLoadedIDList():
        node = addNode(vehicle)
        #print(str(vehicle)+ "   "+str(node))
        g_names[vehicle] = node
        node.mobility = node.node.GetObject(ConstantVelocityMobilityModel.GetTypeId())
        node.mobility.SetPosition(posOutOfBound)
        node.mobility.SetVelocity(Vector(0, 0, 0))
        node.time = -1
        node.adjustment = False
        vehicleList.append(vehicle)
    print(len(vehicleList))
        
    g_traciDryRun.close()

time_step = 1

def setSpeedToReachNextWaypoint(node, referencePos, targetPos, targetTime, referenceSpeed):
    prevPos = node.mobility.GetPosition()
    if prevPos.z < 0:
        raise RuntimeError("Can only calculate waypoint speed for the initially positioned nodes")

    # prevPos and referencePos need to be reasonably similar
    error = Vector(abs(prevPos.x - referencePos.x), abs(prevPos.y - referencePos.y), 0)
    if error.x > 0.1 or error.y > 0.1:
        print(">> Node [%s] Position %s, expected to be at %s" % (node.name, prevPos, referencePos))
        print(">> Node [%s] Position error: %s (now = %f seconds)" % (node.name, str(error), Simulator.Now().To(Time.S).GetDouble()))
        raise RuntimeError("Something off with node positioning; reference and actual current position differ over 10cm")

    distance = Vector(targetPos.x - prevPos.x, targetPos.y - prevPos.y, 0)

    distanceActual = math.sqrt(math.pow(distance.x, 2) + pow(distance.y, 2))
    estimatedSpeedActual = distanceActual / targetTime

    estimatedSpeed = Vector(distance.x / targetTime, distance.y / targetTime, 0)
    
    #x = targetPos.x + estimatedSpeed.x
    #y = targetPos.y + estimatedSpeed.y
    #if(x<=0 or x>=1000 or y<=0 or y>=1000):
        #node.mobility.SetPosition(posOutOfBound)
        #node.mobility.SetVelocity(Vector(0, 0, 0))
        
    #else:
    node.mobility.SetVelocity(estimatedSpeed)
    # print("Node [%s] change speed to [%s] (now = %f seconds); reference speed %f, current position: %s, target position: %s" % (node.name, str(estimatedSpeed), Simulator.Now().To(Time.S).GetDouble(), referenceSpeed, str(prevPos), str(targetPos)))
def prepositionNode(node, targetPos, currentSpeed, angle, targetTime):
    '''This one is trying to set initial position of the node in such a way so it will be
       traveling at currentSpeed and arrives at the targetPos (basically, set position using reverse speed)'''

    #print("Node [%s] will arrive at [%s] in %f seconds (now = %f seconds)" % (node.name, str(targetPos), targetTime, Simulator.Now().To(Time.S).GetDouble()))

    speed = Vector(currentSpeed * math.sin(angle * math.pi / 180), currentSpeed * math.cos(angle * math.pi / 180), 0.0)

    #print(str(speed), currentSpeed, angle, currentSpeed* math.cos(angle * math.pi / 180), currentSpeed * math.sin(angle * math.pi / 180))

    prevPos = Vector(targetPos.x + targetTime * -speed.x, targetPos.y + targetTime * -speed.y, 0)
    #print("          initially positioned at [%s] with speed [%s] (sumo speed %f)" % (str(prevPos), str(speed), currentSpeed))

    node.mobility.SetPosition(prevPos)
    node.mobility.SetVelocity(speed)



def getTargets(vehicle):
    pos = []

    # get the lane id in which the vehicle is currently on
    currentLaneId = g_traciStepByStep.vehicle.getLaneID(vehicle)
    currentLane = net.getLane(currentLaneId)

    x, y = sumolib.geomhelper.positionAtShapeOffset(currentLane.getShape(), currentLane.getLength())

    # Position at the end of the current lane
    y = y + 16
    pos.append(Vector(x, y, 0))

    #for connection in currentLane.getOutgoing():
        #nextLane = connection.getToLane()
        #x, y = sumolib.geomhelper.positionAtShapeOffset(nextLane.getShape(), 0)
        #pos.append(Vector(x, y, 0))

    return pos

def runSumoStep():
    Simulator.Schedule(Seconds(time_step), runSumoStep)

    nowTime = Simulator.Now().To(Time.S).GetDouble()
    targetTime = Simulator.Now().To(Time.S).GetDouble() + time_step

    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble() + time_step)
    requireAdjustment = BooleanValue()
    noAdjustment = BooleanValue(False)
    # print(nowTime, g_traciStepByStep.vehicle.getIDList())
    for vehicle in g_traciStepByStep.vehicle.getIDList():
        node = g_names[vehicle]
        
        pos = g_traciStepByStep.vehicle.getPosition(vehicle)
        speed = g_traciStepByStep.vehicle.getSpeed(vehicle)
        angle = g_traciStepByStep.vehicle.getAngle(vehicle)
        accel = g_traciStepByStep.vehicle.getAcceleration(vehicle)
        distanceTravelled = g_traciStepByStep.vehicle.getDistance(vehicle)
        
        if(vehicle =="f7.0"):
            node.apps.GetAttribute("DoesRequireAdjustment",requireAdjustment)
            # print(requireAdjustment.Get())
            # check if the node requires any speed adjustment
            if(requireAdjustment.Get()):
                print("Now the car will adjust speed ")
                speedAdjustment(vehicle)
                node.apps.SetAttribute("DoesRequireAdjustment",noAdjustment)
            
            if (20 < findDistance(pos[0],pos[1],500.0,500.0) < 300 and distanceTravelled < 500):
                # print(vehicle)
                targets = getTargets(vehicle)
                #print("          Points of interests:", [str(target) for target in targets])
                sendInterest(vehicle,targets)
            
            csv_writer.writerow([nowTime,speed,accel, pos[0],pos[1]])
            
        if node.time < 0: # a new node
            node.time = targetTime
            prepositionNode(node, Vector(pos[0], pos[1], 0.0), speed, angle, targetTime - nowTime)
            node.referencePos = Vector(pos[0], pos[1], 0.0)

            targets = getTargets(vehicle)
            #print("          Points of interests:", [str(target) for target in targets])
        else:
            node.time = targetTime
            setSpeedToReachNextWaypoint(node, node.referencePos, Vector(pos[0], pos[1], 0.0), targetTime - nowTime, speed)
            node.referencePos = Vector(pos[0], pos[1], 0.0)
        g_traciStepByStep.vehicle.setSpeedMode(vehicle,0)
        g_traciStepByStep.vehicle.setMinGap(vehicle,0)
        #g_traciStepByStep.vehicle.setActionStepLength(vehicle,2,False)
        #g_traciStepByStep.vehicle.setTau(vehicle,4)
        #g_traciStepByStep.vehicle.setEmergencyDecel(vehicle,4.1)
        #if((pos[0] < 20.0 or pos[0] > 980.0 or pos[1] < 20.0 or pos[1] > 980.0) and node.time > 10):
            #node.mobility.SetPosition(posOutOfBound)
            #node.mobility.SetVelocity(0)
def findDistance(x1, y1, x2, y2):
    return math.sqrt(math.pow((x1-x2),2) + math.pow((y1-y2),2))

def findPoint(x1, y1, x2,
          y2, x, y) :
    if (x > x1 and x < x2 and
        y > y1 and y < y2) :
        return True
    else :
        return False

def diff(li1, li2):
    return (list(set(li1) - set(li2)))

passingVehicle_step = 0.5

def passingVehicle():
    Simulator.Schedule(Seconds(passingVehicle_step), passingVehicle)
    nowTime = Simulator.Now().To(Time.S).GetDouble()
    
    for vehicle in vehicleList:
        node = g_names[vehicle]
        position = node.mobility.GetPosition()
        if (findPoint(485,485,515,515,position.x,position.y)):
            nowList.append(vehicle)
    global prevList, departedCount
    departList = diff(prevList,nowList)
    prevList = nowList[:]
    nowList.clear()
    
    #print(len(departList))
    departedCount = departedCount + len(departList)
    # csv_writer.writerow([nowTime,len(departList),departedCount])

# this module will adjust the speed of vehicle in such a way that it will reduce the final distance travlled by 2 meter to avoid a collision. In the first module it will reduce the speed by 2m in 1s and then again regain the same speed in next second by scheduling the speedUP module.
def speedAdjustment(vehID):
    node = g_names[vehID]
    node.adjustment = True
    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble())
    oldSpeed = g_traciStepByStep.vehicle.getSpeed(vehID)
    newSpeed = oldSpeed - 4
    g_traciStepByStep.vehicle.slowDown(vehID,newSpeed,1)
    print("New speed of "+ vehID+ " should be: "+str(newSpeed))
    # Simulator.Schedule(Seconds(1), speedUP, vehID, oldSpeed)

def speedUP(vehID,oldSpeed):
    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble())
    newSpeed = oldSpeed + 2
    g_traciStepByStep.vehicle.slowDown(vehID,newSpeed,1)

consumerAppHelper = ndn.AppHelper("ndn::v2v::Consumer")

def test():
    consumerNode = g_names["f7.0"]
    # print(consumerNode.node)
    apps = consumerAppHelper.Install(consumerNode.node)
    apps.Start(Seconds(0.1))
    consumerNode.apps = apps.Get(0)

def installAllConsumerApp():
    for vehicle in vehicleList:
        consumerNode = g_names[vehicle]
        # print(consumerNode.node)
        apps = consumerAppHelper.Install(consumerNode.node)
        apps.Start(Seconds(0.1))
        consumerNode.apps = apps.Get(0)

def installAllProducerApp():
    for vehicle in vehicleList:
        producerNode = g_names[vehicle]
        # print(producerNode.node)
        proapps = producerAppHelper.Install(producerNode.node)
        proapps.Start(Seconds(0.5))
        producerNode.proapps = proapps.Get(0)
        
def sendInterest(vehID,targets):
    # print(vehID)
    consumerNode = g_names[vehID]
    for target in targets:
        consumerNode.apps.SetAttribute("RequestPositionStatus", StringValue(str(target)))
   
def test2():
    consumerNode = g_names["f2.0"]
    consumerNode.apps.SetAttribute("RequestPositionStatus", StringValue("486.4:495.2:0"))
    
createAllVehicles(cmd.duration.To(Time.S).GetDouble())
producerAppHelper = ndn.AppHelper("ndn::v2v::Producer")
# consumerNode = g_names["f1.1"]
# print(consumerNode.node)

# consumerApp = ndn.AppHelper("ndn::v2v::Consumer")
# apps = consumerApp.Install(consumerNode.node)

#Simulator.Schedule(Seconds(0.1), test)
test()
#installAllConsumerApp()
installAllProducerApp()

#Simulator.Schedule(Seconds(5.1), test2)


Simulator.Schedule(Seconds(1), runSumoStep)

Simulator.Schedule(Seconds(1), passingVehicle)


Simulator.Stop(cmd.duration)
Simulator.Run()

g_traciStepByStep.close()
traci.close()

