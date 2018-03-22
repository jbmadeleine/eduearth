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
if len(args) == 0: args = "histhf.nc"
fi=args

# Pour tracer des cartes
#------------------------------------------------------------------
tt = 84600
windvel,x,y,z,t = pp(file=fi,var="wind10m",t=tt).getfd()
slp = pp(file=fi,var="slp",t=tt).getf()
slp = slp/1E2
#------------------------------------------------------------------

# Pour tracer des cartes
#------------------------------------------------------------------
p = plot2d()
p.f = windvel
p.c = slp
p.x = x
p.y = y
#p.proj = "cyl"
p.fmt = "%.2f"
p.title = 'Wind velocity and sea level pressure'
p.units = 'm/s'
# For colors, see https://matplotlib.org/1.4.3/users/colormaps.html
p.colorbar = 'jet'
p.clab = 'True' # contour
p.cfmt = "%3.0f" # format contour
p.makeshow()
#------------------------------------------------------------------
