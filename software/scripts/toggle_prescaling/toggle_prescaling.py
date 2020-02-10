#!/usr/bin/env python3
#import setupLibPaths
import TimeToolDev
#import sys
#import time
#import gc
#import IPython
#import argparse
#import yaml
from psalg.configdb.typed_json import cdict
import psalg.configdb.configdb as cdb
#import os
#import io



def toggle_prescaling():

    create = False
    dbname = 'configDB'
    instrument = 'TMO'
    mycdb = cdb.configdb('mcbrowne:psana@psdb-dev:9306', instrument, create, dbname)
    my_dict = mycdb.get_configuration("BEAM","tmotimetool")

    top = cdict()
    top.setInfo('timetool', 'tmotimetool', 'serial1234', 'No comment')
    top.setAlg('timetoolConfig', [0,0,1])

    

    #print()


    #################################################################
    cl = TimeToolDev.TimeToolDev(
        dev       = '/dev/datadev_0',
        dataDebug = False,
        version3  = False,
        pollEn    = False,
        initRead  = False,
        enVcMask  = 0xD,
    )

    #################################################################

    if(cl.Hardware.PgpMon[0].RxRemLinkReady.get() != 1):
        raise ValueError(f'PGP Link is down' )
        
    #################################################################


    #cl.StartRun()
    #time.sleep(x)
    #cl.StopRun()

    #prescaling = cl.Application.AppLane[0].Prescale.ScratchPad.get()
    prescaling = my_dict['cl']['Application']['AppLane1']['Prescale']['ScratchPad']
    print("old database prescaler value = ",prescaling)
    if(prescaling == 2):
        prescaling = 6
    else:
        prescaling = 2

    
    cl.Application.AppLane[0].Prescale.ScratchPad.set(prescaling)

    print("new rogue prescaler value = ",cl.Application.AppLane[0].Prescale.ScratchPad.get())
    

    top.set("cl.Application.AppLane1.Prescale.ScratchPad",int(prescaling),'UINT32')
    mycdb.modify_device('BEAM', top)

    cl.stop()

if __name__ == "__main__":
    toggle_prescaling()
