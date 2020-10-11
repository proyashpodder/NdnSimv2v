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

g_interestSendingDelay = UniformRandomVariable()
g_interestSendingDelay.SetAttribute("Min", DoubleValue(0.0))
g_interestSendingDelay.SetAttribute("Max", DoubleValue(0.5))

g_speedAdjustmentVelocity = UniformRandomVariable()
g_speedAdjustmentVelocity.SetAttribute("Min", DoubleValue(float(cmd.minDecel)))
g_speedAdjustmentVelocity.SetAttribute("Max", DoubleValue(float(cmd.maxDecel)))


from ns.mobility import MobilityModel, ConstantVelocityMobilityModel

if not cmd.output:
    cmd.output = 'numbers-%d' % int(cmd.baseline)

data_file = open('results/%s-run-%d-min-%f-max-%f.csv' % (cmd.output, cmd.run,float(cmd.minDecel),float(cmd.maxDecel)), 'w')

rates_file = 'results/%s-rates-run-%d-min-%f-max-%f.csv' % (cmd.output, cmd.run,float(cmd.minDecel),float(cmd.maxDecel))
app_delays_file = 'results/%s-app-delays-run-%d-min-%f-max-%f.csv' % (cmd.output, cmd.run,float(cmd.minDecel),float(cmd.maxDecel))

csv_writer = csv.writer(data_file)
csv_writer.writerow(["Duration","Total_Number_Of_Vehicle","Total_Adjusted_Car","Total_Collided_Car","Total_Passed_Car","Total_AdjustedNot_CollidedCar","totalCollidedNotAdjustedCar","totalAdjustedButCollidedCar","totalAdjustedAndPassedCar"])

file = open('results/%s-risky-decelerations-run-%d.csv' % (cmd.output, cmd.run), 'w')
csv_writer1 = csv.writer(file)
csv_writer1.writerow(["Duration","Total_Number_Of_Vehicle","Total_Risky_Deceleration_Count","Total_Number_Of_Risky_Decelerated_Car"])


net = sumolib.net.readNet('%s.net.xml' % cmd.traceFile)
sumoCmd = ["sumo", "-c", "%s.sumocfg" % cmd.traceFile]

traci.start(sumoCmd, label="dry-run") # whole run to estimate and created all nodes with out of bound position and 0 speeds
g_traciDryRun = traci.getConnection("dry-run")

traci.start(sumoCmd, label="step-by-step")
g_traciStepByStep = traci.getConnection("step-by-step")

g_names = {}
p_names = {}
vehicleList = []
prevList = []
nowList = []
collidedThisSecond = []
collidedPreviousSecond = []
adjusted = []
collided = []
passed = []

posOutOfBound = Vector(0, 0, -2000)
departedCount = 0
totalCollisionCount = 0
riskyDeceleration = 0
numberOfLoadedVehicle = 0

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
        node.needAdjustment = False
        node.passedIntersection = False
        node.collision = False
        node.riskyDeceleration = False
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

    x = targetPos.x + estimatedSpeed.x
    y = targetPos.y + estimatedSpeed.y
    #if(x<=0 or x>=1000 or y<=0 or y>=1000):
        #node.mobility.SetPosition(posOutOfBound)
        #node.mobility.SetVelocity(Vector(0, 0, 0))
    # print("Node [%s] change speed to [%s] (now = %f seconds); reference speed %f, current position: %s, target position: %s" % (node.name, str(estimatedSpeed), Simulator.Now().To(Time.S).GetDouble(), referenceSpeed, str(prevPos), str(targetPos)))
    #else:
    node.mobility.SetVelocity(estimatedSpeed)

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

    numberOfInterest = int(cmd.numberOfInterest)

    interestNumber = 1
    fraction = math.floor(28/(numberOfInterest+1))
    half = math.floor(numberOfInterest/2)
    if(currentLaneId[0] == "1"):
        if(currentLaneId == "1i_3"):
            while(interestNumber <= half):
                pos.append(Vector(x+(interestNumber*fraction),y,0))
                interestNumber = interestNumber + 1
            if(numberOfInterest % 2 != 0):
                pos.append(Vector(500, 500, 0))
            interestNumber = 1
            while(interestNumber <= half):
                pos.append(Vector(x+15, 500+(interestNumber*fraction),0))
                interestNumber = interestNumber + 1
        else:
            while(interestNumber <= numberOfInterest):
                pos.append(Vector(x+(interestNumber*fraction),y,0))
                interestNumber = interestNumber + 1
    elif(currentLaneId[0] == "2"):
        if(currentLaneId == "2i_3"):
           while(interestNumber <= half):
               pos.append(Vector(x-(interestNumber*fraction),y,0))
               interestNumber = interestNumber + 1
           if(numberOfInterest %2 != 0):
               pos.append(Vector(500, 500, 0))
           interestNumber = 1
           while(interestNumber <= half):
               pos.append(Vector(x-15, 500-(interestNumber*fraction),0))
               interestNumber = interestNumber + 1
        else:
            while(interestNumber <= numberOfInterest):
                pos.append(Vector(x-(interestNumber*fraction),y,0))
                interestNumber = interestNumber + 1
    elif(currentLaneId[0] == "3"):
        if(currentLaneId == "3i_3"):
            while(interestNumber <= half):
                pos.append(Vector(x,y+(interestNumber*fraction),0))
                interestNumber = interestNumber + 1
            if(numberOfInterest %2 != 0):
                pos.append(Vector(500, 500, 0))
            interestNumber = 1
            while(interestNumber <= half):
                pos.append(Vector(500-(interestNumber*fraction), y+15,0))
                interestNumber = interestNumber + 1
        else:
            while(interestNumber <= numberOfInterest):
                pos.append(Vector(x,y+(interestNumber*fraction),0))
                interestNumber = interestNumber + 1
    elif(currentLaneId[0] == "4"):
        if(currentLaneId == "4i_3"):
            while(interestNumber <= half):
                pos.append(Vector(x,y-(interestNumber*fraction),0))
                interestNumber = interestNumber + 1
            if(numberOfInterest %2 != 0):
                pos.append(Vector(500, 500, 0))
            interestNumber = 1
            while(interestNumber <= half):
                pos.append(Vector(500+(interestNumber*fraction), y-15,0))
                interestNumber = interestNumber + 1
        else:
            while(interestNumber <= numberOfInterest):
                pos.append(Vector(x,y-(interestNumber*fraction),0))
                interestNumber = interestNumber + 1
    # Position at the end of the current lane
    #pos.append(Vector(x, y, 0))

    #for connection in currentLane.getOutgoing():
        #nextLane = connection.getToLane()
        #x, y = sumolib.geomhelper.positionAtShapeOffset(nextLane.getShape(), 0)
        #pos.append(Vector(x, y, 0))

    return pos

def runSumoStep():
    Simulator.Schedule(Seconds(time_step), runSumoStep)
    global totalCollisionCount, collidedPreviousSecond, riskyDeceleration, adjusted, collided, passed, numberOfLoadedVehicle
    nowTime = Simulator.Now().To(Time.S).GetDouble()
    targetTime = Simulator.Now().To(Time.S).GetDouble() + time_step

    collisionCount = 0

    print ("Now", Simulator.Now().To(Time.S).GetDouble())
    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble() + time_step)

    numberOfVehicle = g_traciStepByStep.simulation.getLoadedNumber()

    numberOfLoadedVehicle = numberOfLoadedVehicle + numberOfVehicle

    # print(numberOfLoadedVehicle)

    requireAdjustment = BooleanValue()
    noAdjustment = BooleanValue(False)
    # print(nowTime, g_traciStepByStep.vehicle.getIDList())
    for vehicle in g_traciStepByStep.vehicle.getIDList():
        node = g_names[vehicle]
        if getattr(node, 'apps', None):
            node.apps.GetAttribute("DoesRequireAdjustment", requireAdjustment)
        pos = g_traciStepByStep.vehicle.getPosition(vehicle)
        speed = g_traciStepByStep.vehicle.getSpeed(vehicle)
        angle = g_traciStepByStep.vehicle.getAngle(vehicle)
        accel = g_traciStepByStep.vehicle.getAcceleration(vehicle)
        distanceTravelled = g_traciStepByStep.vehicle.getDistance(vehicle)

        if(speed < 0.5 and findPoint(485,485,515,515,pos[0],pos[1]) and node.collision == False):
            node.collision = True
            print("vehicle: "+ str(vehicle)+ " has a collision")
            collisionCount = collisionCount + 1
            collidedThisSecond.append(node)
            # node.mobility.SetPosition(posOutOfBound)
            # node.mobility.SetVelocity(Vector(0,0,0))

        if(accel < -7.0):
            riskyDeceleration = riskyDeceleration + 1
            print("At "+ str(nowTime)+" vehicle " + str(vehicle)+ " has made a risky deceleration at rate: "+ str(accel))
            node.riskyDeceleration = True

        # check if the node requires any speed adjustment
        if requireAdjustment.Get():
            print("Vehicle "+str(vehicle)+" will adjust speed")
            speedAdjustment(vehicle)
            node.needAdjustment = True

        if getattr(node, 'apps', None) and (20 < findDistance(pos[0],pos[1],500.0,500.0) < 300) and distanceTravelled < 500:
            # print(vehicle)
            targets = getTargets(vehicle)
            #print("Vehicle:   "+vehicle+"          Points of interests:", [str(target) for target in targets])
            # print("vehicle: "+str(vehicle)+" travelled: "+str(distanceTravelled))
            Simulator.Schedule(Seconds(g_interestSendingDelay.GetValue()), sendInterest, vehicle, targets)

        if node.time < 0: # a new node
            node.time = targetTime
            prepositionNode(node, Vector(pos[0], pos[1], 0.0), speed, angle, targetTime - nowTime)
            node.referencePos = Vector(pos[0], pos[1], 0.0)

            targets = getTargets(vehicle)
            print("Vehicle:   "+vehicle+"          Points of interests:", [str(target) for target in targets])
        else:
            node.time = targetTime
            setSpeedToReachNextWaypoint(node, node.referencePos, Vector(pos[0], pos[1], 0.0), targetTime - nowTime, speed)
            node.referencePos = Vector(pos[0], pos[1], 0.0)
        g_traciStepByStep.vehicle.setSpeedMode(vehicle,0)
        g_traciStepByStep.vehicle.setMinGap(vehicle,0.5)
        #if((pos[0] < 20.0 or pos[0] > 980.0 or pos[1] < 20.0 or pos[1] > 980.0) and node.time > 10):
            #node.mobility.SetPosition(posOutOfBound)
            #node.mobility.SetVelocity(0)
    collided = collidedThisSecond + collidedPreviousSecond

    for i in range (0,len(collided)-1):
        for j in range (i+1, len(collided)):
            pos1 = collided[i].mobility.GetPosition()
            pos2 = collided[j].mobility.GetPosition()
            print(findDistance(pos1.x,pos1.y,pos2.x,pos2.y))
            if(findDistance(pos1.x,pos1.y,pos2.x,pos2.y) < 5):
                collisionCount = collisionCount - 1

    collidedPreviousSecond = collidedThisSecond[:]
    collidedThisSecond.clear()

    totalCollisionCount = totalCollisionCount + collisionCount

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

def intersection(li1, li2):
    return (list(set(li1) & set(li2)))

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
    for v in departList:
        n = g_names[v]
        n.passedIntersection = True

    departedCount = departedCount + len(departList)

# this module will adjust the speed of vehicle in such a way that it will reduce the final distance travlled by 2 meter to avoid a collision. In the first module it will reduce the speed by 2m in 1s and then again regain the same speed in next second by scheduling the speedUP module.
def speedAdjustment(vehID):
    node = g_names[vehID]
    node.adjustment = True
    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble())
    oldSpeed = g_traciStepByStep.vehicle.getSpeed(vehID)
    deceleration = g_speedAdjustmentVelocity.GetValue()
    newSpeed = max(oldSpeed - 2*deceleration, 0.0) # 2* because of a bug in the code
    g_traciStepByStep.vehicle.slowDown(vehID, newSpeed, 1)
    print("Speed of "+ vehID+ " to be adjusted by %f.2 in 1 sec" % -deceleration)
    Simulator.Schedule(Seconds(1), speedUP, vehID, oldSpeed)

def speedUP(vehID, oldSpeed):
    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble())
#     newSpeed = oldSpeed + round(random.uniform(3,6), 2)
    g_traciStepByStep.vehicle.slowDown(vehID, oldSpeed, 1)

def installAllConsumerApp():
    for vehicle in vehicleList:
        consumerNode = g_names[vehicle]
        apps = consumerAppHelper.Install(consumerNode.node)
        apps.Start(Seconds(0.1))
        consumerNode.apps = apps.Get(0)

def installAllProducerApp():
    for vehicle in vehicleList:
        producerNode = g_names[vehicle]
        proapps = producerAppHelper.Install(producerNode.node)
        proapps.Start(Seconds(0.5))
        producerNode.proapps = proapps.Get(0)

def sendInterest(vehID,targets):
    # print(vehID)
    consumerNode = g_names[vehID]
    # print("sending Interest at: " + str(Simulator.Now().To(Time.S).GetDouble()))
    for target in targets:
        consumerNode.apps.SetAttribute("RequestPositionStatus", StringValue(str(target)))

def writeToFile():
    adjusted = []
    collided = []
    passed = []
    global numberOfLoadedVehicle
    nowTime = Simulator.Now().To(Time.S).GetDouble()
    for vehicle in vehicleList:
        node = g_names[vehicle]
        if(node.needAdjustment):
            adjusted.append(vehicle)
        if(node.collision):
            collided.append(vehicle)
        if(node.passedIntersection):
            passed.append(vehicle)
    adjustedNotCollided = diff(adjusted,collided)
    collidedNotAdjusted = diff(collided,adjusted)
    adjustedButCollided = intersection(adjusted, collided)
    adjustedAndPassed = intersection(adjusted,passed)
    collidedButPassed = intersection(collided,passed)

    csv_writer.writerow([nowTime, numberOfLoadedVehicle, len(adjusted), len(collided), len(passed), len(adjustedNotCollided), len(collidedNotAdjusted), len(adjustedButCollided), len(adjustedAndPassed) ])

    Simulator.Schedule(Seconds(10.0), writeToFile)

def risky_decelerations():
    risky = []
    nowTime = Simulator.Now().To(Time.S).GetDouble()
    for vehicle in vehicleList:
        node = g_names[vehicle]
        if(node.riskyDeceleration):
            risky.append(vehicle)
    csv_writer1.writerow([nowTime, numberOfLoadedVehicle, riskyDeceleration, len(risky)])

    Simulator.Schedule(Seconds(10.0), risky_decelerations)

createAllVehicles(cmd.duration.To(Time.S).GetDouble())

if not cmd.baseline or int(cmd.baseline) != 1:
    consumerAppHelper = ndn.AppHelper("ndn::v2v::Consumer")
    producerAppHelper = ndn.AppHelper("ndn::v2v::Producer")

    installAllConsumerApp()
    installAllProducerApp()

Simulator.Schedule(Seconds(1), runSumoStep)

Simulator.Schedule(Seconds(1), passingVehicle)

Simulator.Schedule(Seconds(10.0), writeToFile)

Simulator.Schedule(Seconds(10.0), risky_decelerations)

ndn.L3RateTracer.InstallAll(rates_file, Seconds(10.0))
ndn.AppDelayTracer.InstallAll(app_delays_file)


Simulator.Schedule(cmd.duration - NanoSeconds(1), ndn.AppDelayTracer.Destroy)

Simulator.Stop(cmd.duration)
Simulator.Run()

g_traciStepByStep.close()
traci.close()
