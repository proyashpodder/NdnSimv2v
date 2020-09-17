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
import ns.network
import ns.applications

time_step = 1

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

traffic_file = open('results/baseline-traffic-1.csv', 'w')
writer = csv.writer(traffic_file)
writer.writerow(["Time","PacketsRaw","KilobytesRaw"])

net = sumolib.net.readNet('%s.net.xml' % cmd.traceFile)
sumoCmd = ["sumo", "-c", "%s.sumocfg" % cmd.traceFile]

traci.start(sumoCmd, label="dry-run") # whole run to estimate and created all nodes with out of bound position and 0 speeds
g_traciDryRun = traci.getConnection("dry-run")

traci.start(sumoCmd, label="step-by-step")
g_traciStepByStep = traci.getConnection("step-by-step")

g_names = {}
p_names = {}
vehicleList = []
personList = []
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

totalNumberOfPedestrian = 0
totalTraffic = 0

container = ns.network.NodeContainer()


def createAllVehicles(simTime):
    g_traciDryRun.simulationStep(simTime)
    global container
    #vehicleList = g_traciDryRun.simulation.getLoadedIDList()
    persons = g_traciDryRun.person.getIDList()
    for person in persons:
        #print(person)
        node = addNode(person)
        #print(person)
        container.Add(node.node)
        
        # appss.Add(client.Install(node.node))
        p_names[person] = node
        node.mobility = node.node.GetObject(ConstantVelocityMobilityModel.GetTypeId())
        node.mobility.SetPosition(posOutOfBound)
        node.mobility.SetVelocity(Vector(0, 0, 0))
        node.time = -1
        personList.append(person)
    
    for vehicle in g_traciDryRun.simulation.getLoadedIDList():
        node = addNode(vehicle)
        # container.Add(node.node)
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
    
    port = 9   # Discard port(RFC 863)
    
    # one approach for sending UDP packets
    appss = ns.network.ApplicationContainer()
    client = ns.applications.UdpClientHelper(ns.network.Address(ns.network.InetSocketAddress(ns.network.Ipv4Address("10.0.0.1"), port)))

    client.SetAttribute("Interval",TimeValue(Seconds(1)))
    client.SetAttribute("PacketSize",UintegerValue(350))
    # client.Send()
    appss.Add(client.Install(container))
    appss.Start(Seconds(1.0))
    
    # another approach of sending UDP packets
    onOff = ns.applications.OnOffHelper("ns3::UdpSocketFactory",
                                  ns.network.Address(ns.network.InetSocketAddress(ns.network.Ipv4Address("10.0.0.1"), port)))
    # onOff.SetAttribute("DataRate", ns.network.DataRateValue(ns.network.DataRate("100kbps")))
    onOff.SetConstantRate (ns.network.DataRate ("350kb/s"), 350)
    apps = onOff.Install(container)
    apps.Start(ns.core.Seconds(1))
    apps.Stop(ns.core.Seconds(cmd.duration - Seconds(1)))
    
    tr = ns.applications.UdpTraceClientHelper(ns.network.Address(ns.network.InetSocketAddress(ns.network.Ipv4Address("10.0.0.1"), port)),"")
    aps = ns.network.ApplicationContainer()
    aps.Add(tr.Install(container))
    aps.Start(Seconds(1.0))
    
    g_traciDryRun.close()

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


def runSumoStep():
    Simulator.Schedule(Seconds(time_step), runSumoStep)
    global totalCollisionCount, collidedPreviousSecond, riskyDeceleration, adjusted, collided, passed, numberOfLoadedVehicle, numberOfPedestrian, totalTraffic, totalNumberOfPedestrian
    nowTime = Simulator.Now().To(Time.S).GetDouble()
    targetTime = Simulator.Now().To(Time.S).GetDouble() + time_step

    collisionCount = 0
    


    print ("Now", Simulator.Now().To(Time.S).GetDouble())
    g_traciStepByStep.simulationStep(Simulator.Now().To(Time.S).GetDouble() + time_step)
    
    if(nowTime % 10 == 0):
        totalTraffic = 0
        totalNumberOfPedestrian = 0
    numberOfVehicle = g_traciStepByStep.simulation.getLoadedNumber()
    numberOfLoadedVehicle = numberOfLoadedVehicle + numberOfVehicle
    
    numberOfPedestrian = len(g_traciStepByStep.person.getIDList())
    print(numberOfPedestrian)
    print(g_traciStepByStep.person.getIDList())
    totalNumberOfPedestrian = totalNumberOfPedestrian + numberOfPedestrian
    traffic = numberOfPedestrian * 350
    totalTraffic = totalTraffic + traffic
    print(totalNumberOfPedestrian)
    print(totalTraffic)

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


        if node.time < 0: # a new node
            node.time = targetTime
            prepositionNode(node, Vector(pos[0], pos[1], 0.0), speed, angle, targetTime - nowTime)
            node.referencePos = Vector(pos[0], pos[1], 0.0)
            
        else:
            node.time = targetTime
            setSpeedToReachNextWaypoint(node, node.referencePos, Vector(pos[0], pos[1], 0.0), targetTime - nowTime, speed)
            node.referencePos = Vector(pos[0], pos[1], 0.0)
        # g_traciStepByStep.vehicle.setSpeedMode(vehicle,0)
        # g_traciStepByStep.vehicle.setMinGap(vehicle,0.5)
        #if((pos[0] < 20.0 or pos[0] > 980.0 or pos[1] < 20.0 or pos[1] > 980.0) and node.time > 10):
            #node.mobility.SetPosition(posOutOfBound)
            #node.mobility.SetVelocity(0)
    collided = collidedThisSecond + collidedPreviousSecond

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

def trafficCount():
    writer.writerow([Simulator.Now().To(Time.S).GetDouble(),totalNumberOfPedestrian, totalTraffic/1000])
    #totalTraffic = 0
    Simulator.Schedule(Seconds(10.0), trafficCount)

createAllVehicles(cmd.duration.To(Time.S).GetDouble())

if not cmd.baseline or int(cmd.baseline) != 1:
    consumerAppHelper = ndn.AppHelper("ndn::v2v::Consumer")
    producerAppHelper = ndn.AppHelper("ndn::v2v::Producer")

    # installAllConsumerApp()
    # installAllProducerApp()

Simulator.Schedule(Seconds(1), runSumoStep)

ndn.L3RateTracer.InstallAll(rates_file, Seconds(10.0))
ndn.AppDelayTracer.InstallAll(app_delays_file)

Simulator.Schedule(cmd.duration - NanoSeconds(1), ndn.AppDelayTracer.Destroy)
Simulator.Schedule(Seconds(10.0), trafficCount)
Simulator.Stop(cmd.duration)
Simulator.Run()

g_traciStepByStep.close()
traci.close()

