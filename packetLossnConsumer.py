import os

for i in range (1,21):
    path = './waf --run="packetLossnConsumer --tmin=1 ==tmax=2 --consumer='+str(i)+'"'
    print(path)
    os.system(path)
