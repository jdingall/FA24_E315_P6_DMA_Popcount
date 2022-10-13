import numpy as np

from pynq import Overlay
from pynq import MMIO
from pynq import allocate

    
    
class DMAPopcount():
    
    def __init__(self):
        try: 
            self.overlay = Overlay('bitstream.bit')        
            self.mmio = self.overlay.axi_popcount_0.S_AXI_LITE
            self.dma = self.overlay.axi_dma_0       
        except:  
            raise Exception("Cound not find bitstream.bit")

    def name(self):
        return self.__class__.__name__ 
    
    def mmioReset(self):
        self.mmio.write(0x0, 0x1)
        pass
        
    def mmioRead(self):
        return self.mmio.read(0x4)
        return 0;
    
    def countInt(self,n):
        #FIXME
        return 0
    
    def countArray(self, buf):
        #FIXME
        return 0        
        
    def countFile(self,file):
        f = open(file, "r")
        buf = np.fromfile(f, dtype=np.int32)
        return self.countArray(buf) 
        

