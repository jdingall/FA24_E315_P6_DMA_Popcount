#!/usr/bin/env python3

import argparse
import json
import os
import shutil
import subprocess
import re


class Helper():

    def __init__(self, vivado=None):

        self.MY_DIR = os.path.dirname(os.path.realpath(__file__))
        self.JF = self.MY_DIR + '/.data.json'
        self.J = self.load_json()

        self.priv_key = self.MY_DIR + '/.id_rsa.xilinx.priv'
        self.vivado = vivado

    def load_json(self):
        if os.path.exists( self.JF):
            with open(self.JF, 'r') as f:
                return json.load(f)
        else:
            return {"IP": "192.168.2.99", "Proj": "P4_Popcount"}

    def save_json(self):
         with open(self.JF, 'w') as f:
            json.dump( self.J, f) 

     

    def run_command(self, command):
        print ('running: ', command)
        result = subprocess.Popen(command, shell=True, executable='/bin/bash', stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        return result.communicate()


    def build_vivado(self,):
        #sanity check
        if os.path.exists( self.MY_DIR + '/vivado_project/vivado_project.xpr'):
            print ("Found Vivado Project, Skipping.")
            return

        command = 'vivado -mode batch -source ' + self.J['Proj'] + '.tcl'

        if self.vivado != None:
            print ("vivado specified from command line")
            command = command.replace('vivado', self.vivado)

        elif shutil.which('vivado') != None:
            print ("Found Vivado")
        else:
            raise Exception("Vivado not found!")

        print ("Building Vivado Project")
        self.run_command(command) 

    def init_pynq(self):
        proj = self.J['Proj']
        ssh = 'ssh -i ' + self.priv_key + ' xilinx@'+self.J['IP'] 

        self.run_command('chmod 0600 ' + self.priv_key)
        
        #sanity check
        if self.run_command(ssh + ' "ls ~/jupyter_notebooks/' + proj + '"')[0] != b'':
            print ("Found Pynq project, Skipping")
            return

        commands = [
                    ssh + ' "mkdir -p ~/tmp" ',
                    ssh + ' "cd ~/tmp && git init --bare" ',
                    'git remote remove tmp', 
                    'git remote add tmp xilinx@' + self.J['IP'] + ':~/tmp/',
                    'GIT_SSH_COMMAND=\'ssh -i '+self.priv_key + '\' git push tmp master', 
                    ssh + ' "git clone tmp ~/jupyter_notebooks/' + proj + ' "',
                    ssh + ' "rm -rf ~/tmp" ',
                    'git remote remove pynq', 
                    'git remote add pynq xilinx@' + self.J['IP'] + ':~/jupyter_notebooks/' + proj,
                    'GIT_SSH_COMMAND=\'ssh -i '+self.priv_key + '\' git push pynq master', 
                   ]   
        for command in commands:                     
            self.run_command(command)

    def load_bitstream(self):
        bit =  self.MY_DIR + '/vivado_project/vivado_project.runs/impl_1/design_fpga_wrapper.bit'
        hwh = self.MY_DIR + '/vivado_project/vivado_project.gen/sources_1/bd/design_fpga/hw_handoff/design_fpga.hwh'
        scp = 'scp -i ' + self.priv_key
        pynq = 'xilinx@'+self.J['IP'] + ':~/jupyter_notebooks/' + self.J['Proj'] + '/Pynq/'
        commands = [ 
                scp + ' ' + bit + ' ' + pynq + 'bitstream.bit', 
                scp + ' ' + hwh + ' ' + pynq + 'bitstream.hwh', 
                   ]
        for command in commands:                     
            self.run_command(command)

    def set_ip(self, IP):
        # https://www.geeksforgeeks.org/python-program-to-validate-an-ip-address/
        regex = '''^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
            25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
            25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
            25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)$'''
        if not re.search(regex, IP):  
            print("Invalid IP address, not updating")
            return
        
        if IP == self.J['IP']:
            print ("IPs Match, Skipping")
            return 

        print ("Updating IP Address")
        self.J['IP'] = IP
        self.save_json()

        commands = [ 'git remote remove pynq', 
                     'git remote add pynq xilinx@' + self.J['IP'] + ':~/jupyter_notebooks/' + self.J['Proj'],
                   ]   
        for command in commands:                     
            self.run_command(command)


            

if __name__ == "__main__":

    h = Helper()
    ap = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument('command', choices=['init','bitstream', 'setIp'], 
            help=   'init:initialize the project\n'+
                    'bitstream: upload the bitstream to the Pynq\n'+
                    'setIp: set the Pynq IP Address')
    ap.add_argument('--ip', type=str, nargs='?', help="Ip Address of Pynq")
    ap.add_argument('--vivadoOnly', action='store_true', help="Initialize only the Vivado project")
    ap.add_argument('--pynqOnly', action='store_true', help="Initialize only the Pynq project")
    ap.add_argument('--vivado_bin', type=str, nargs='?', help="Path to Vivado binary")

    args = ap.parse_args()

    print ("Welcome to the E315 Helper Script!")
    print (" Current Pynq IP: ", h.J['IP'])

    args.command = args.command.lower()

    if args.vivado_bin:
        h = Helper( vivado=args.vivado_bin)

    if args.command == 'init':
        print ('Running ', args.command)

        if args.ip:
            h.set_ip(args.ip)
        
        if args.vivadoOnly:
            h.build_vivado()
        elif args.pynqOnly:
            h.init_pynq()
        else:
            h.build_vivado()
            h.init_pynq()

    elif args.command == 'bitstream':
        print ('Running ', args.command)

        if args.ip:
            h.set_ip(args.ip)

        h.load_bitstream()

    elif args.command == 'setip':
        print ('Running ', args.command)

        if args.ip:
            newip = args.ip
        else:
            print ("Please specify a new IP address: ")
            newip = input()
        h.set_ip(newip)



