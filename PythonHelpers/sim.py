import os;
import sys;
nodeNumber = 10;
while nodeNumber <= 200:
    path = './waf --run="cancelasunhelpful --nodeNumber='+str(nodeNumber)+'"';
    print(path)
    os.system(path)
    nodeNumber=nodeNumber+10;

