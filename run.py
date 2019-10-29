#!/usr/bin/env python3
# -*- Mode: python; py-indent-offset: 4; indent-tabs-mode: nil; coding: utf-8; -*-

from subprocess import call
from sys import argv
import os
import subprocess
import workerpool
import multiprocessing
import argparse

######################################################################
######################################################################
######################################################################

parser = argparse.ArgumentParser(description='Simulation runner')
parser.add_argument('scenarios', metavar='scenario', type=str, nargs='*',
                    help='Scenario to run')

parser.add_argument('-l', '--list', dest="list", action='store_true', default=False,
                    help='Get list of available scenarios')

parser.add_argument('-s', '--simulate', dest="simulate", action='store_true', default=False,
                    help='Run simulation and postprocessing (false by default)')

parser.add_argument('-g', '--no-graph', dest="graph", action='store_false', default=True,
                    help='Do not build a graph for the scenario (builds a graph by default)')

args = parser.parse_args()

if not args.list and len(args.scenarios)==0:
    print("ERROR: at least one scenario need to be specified")
    parser.print_help()
    exit (1)

if args.list:
    print("Available scenarios: ")
else:
    if args.simulate:
        print("Simulating the following scenarios: " + ",".join (args.scenarios))

    if args.graph:
        print("Building graphs for the following scenarios: " + ",".join (args.scenarios))

######################################################################
######################################################################
######################################################################

class SimulationJob (workerpool.Job):
    "Job to simulate things"
    def __init__ (self, cmdline):
        self.cmdline = cmdline
    def run (self):
        print(" ".join (self.cmdline))
        subprocess.call (self.cmdline)

pool = workerpool.WorkerPool(size = multiprocessing.cpu_count())

class Processor:
    def run (self):
        if args.list:
            print("    " + self.name)
            return

        if "all" not in args.scenarios and self.name not in args.scenarios:
            return

        if args.list:
            pass
        else:
            if args.simulate:
                self.simulate ()
                pool.join ()
                self.postprocess ()
            if args.graph:
                self.graph ()

    def graph (self):
        pass
        # subprocess.call ("./graphs/%s.R" % self.name, shell=True)

class SuppressionVsNumber(Processor):
    def __init__ (self):
        self.name = "suppression-vs-number"

    def simulate (self):
        cmdline = ["./build/cancelasunhelpful"]

        for nodeNumber in range(10, 210, 10):
            path = cmdline + ["--nodeNumber=%d" % nodeNumber]
            job = SimulationJob(path)
            pool.put(job)

    def postprocess (self):
        # any postprocessing, if any
        pass

class SuppressionVsTimers(Processor):
    def __init__ (self):
        self.name = "suppression-vs-timers"

    def simulate (self):
        cmdline = ["./build/cancelasunhelpful"]

        nodeNumber = 100
        for tmin in [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10]:
            path = cmdline + ["--nodeNumber=%d" % nodeNumber] + ["--tmin=%f" % tmin] + ["--tmax=0.2"]
            job = SimulationJob(path)
            pool.put(job)

    def postprocess (self):
        # any postprocessing, if any
        pass
    
try:
    # Simulation, processing, and graph building
    fig = SuppressionVsNumber()
    fig.run ()

    fig = SuppressionVsTimers()
    fig.run ()

    
finally:
    pool.join ()
    pool.shutdown ()
