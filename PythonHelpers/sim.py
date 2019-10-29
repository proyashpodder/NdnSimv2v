#!/usr/bin/env python3

import os
import sys

for nodeNumber in range(10, 210, 10):
    path = './waf --run="cancelasunhelpful --nodeNumber=%d"' % nodeNumber
    print(path)
    os.system(path)
