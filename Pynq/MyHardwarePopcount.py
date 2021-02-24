import numpy as np

from pynq import Overlay
from pynq import MMIO

class Popcount:
    def name(self):
        return "Popcount"
    
    def countInt(self, n):
        raise Exception("Not Implimented")

    def countArray (self, buf):
        total_ones = 0
        for b in buf:
            total_ones += self.countInt(b)
        return total_ones
        
    def countFile(self,file):
        f = open(file, "r")
        buf = np.fromfile(f, dtype=np.uint32)
        return self.countArray(buf) 

    

class MyHardwarePopcount(Popcount):
    
    def __init__(self):
        self.overlay = Overlay('bitstream.bit')        
        self.mmio = self.overlay.axi_popcount_0.S_AXI_LITE
        # FILL ME IN!

    def name(self):
        return "Hardware_Popcount"
    
    def countInt(self, n): 
        # FILL ME IN!
        return 0
    
## REMOVE ME!S
class MyHardwarePopcount(Popcount):

    def __init__(self):
        self.overlay = Overlay('bitstream.bit')
        self.mmio = self.overlay.axi_popcount_0.S_AXI_LITE        

        self.reset()

    def name(self):
        return "My_Hardware_Popcount"

    def reset(self):
        self.mmio.write(0x0, 0x1)

    def read(self):
        return self.mmio.read(0x4)

    def countInt(self, n):
        self.reset()
        self.mmio.write(0x4,int(n))
        return self.read()
