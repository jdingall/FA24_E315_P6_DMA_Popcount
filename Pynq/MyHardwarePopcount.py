import numpy as np

from pynq import Overlay
from pynq import MMIO
from pynq import allocate

    
    
class MyHardwarePopcount():
    
    def __init__(self, mode='mmio'):
        # UNCOMMENT
        #self.overlay = Overlay('bitstream.bit')        
        #self.mmio = self.overlay.axi_popcount_0.S_AXI_LITE
        #self.dma = self.overlay.axi_dma_0
        
        self.mode = mode        

    def name(self):
        return self.__class__.__name__ + "." + self.mode
    
    def mmioReset(self):
        #UNCOMMENT: self.mmio.write(0x0, 0x1)
        pass
        
    def mmioRead(self):
        #UNCOMMENT: return self.mmio.read(0x4)
        return 0;
    
    def mmioCountInt(self, n): 
        self.mmioReset()
        #UNCOMMENT: self.mmio.write(0x4,int(n))
        return self.mmioRead()
    
    def mmioCountArray (self, buf):
        self.mmioReset()
        total_ones = 0
        for b in buf:
            pass #UNCOMMENT: self.mmio.write(0x4,int(b))
        return self.mmioRead()
    
    def dmaCountInt(self,n):
        #FIXME
        return 0
    
    def dmaCountArray(self, buf):
        #FIXME
        return 0        

    def countInt(self, n):        
        if self.mode == 'mmio':
            return self.mmioCountInt(n)
        else:
            return self.dmaCountInt(n)
                
    def countArray (self, buf):
        if self.mode == 'mmio':
            return self.mmioCountArray(buf)
        else:
            return self.dmaCountArray(buf)
        
    def countFile(self,file):
        f = open(file, "r")
        buf = np.fromfile(f, dtype=np.int32)
        return self.countArray(buf) 
        

