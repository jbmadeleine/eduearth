#! /usr/bin/env python

from ppclass import pp
from ppplot import plot2d
import numpy as np
import scipy.stats
import matplotlib.pyplot as plt
import math as m

# arguments
from optparse import OptionParser ### TBR by argparse
parser = OptionParser()
(opt,args) = parser.parse_args()
if len(args) == 0: args = "resultat.nc"
fi=args

##################################################
lev = 1e5
##################################################

# Pour tracer des cartes
#------------------------------------------------------------------
tt = 84600
uwind,x,y,z,t = pp(file=fi,var="u10m",t=tt,z=lev).getfd()
vwind = pp(file=fi,var="v10m",t=tt,z=lev).getf()
windvel = pp(file=fi,var="wind10m",t=tt,z=lev).getf()
#------------------------------------------------------------------

# Pour tracer des cartes
#------------------------------------------------------------------
p = plot2d()
p.f = windvel
p.x = x
p.y = y
#p.proj = "cyl"
p.fmt = "%.2f"
p.title = 'Wind velocity'
p.units = 'm/s'
p.colorbar = 'gist_ncar'
p.vecx = uwind
p.vecy = vwind
p.makeshow()

#------------------------------------------------------------------
