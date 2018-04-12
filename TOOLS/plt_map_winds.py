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
if len(args) == 0: args = "histmth.nc"
fi=args

# Choix des donnees
#------------------------------------------------------------------
month = 1. # numero du mois
tt = 86400.*30.*(month+0.5)
windvel,x,y,z,t = pp(file=fi,var="wind10m",t=tt).getfd()
slp = pp(file=fi,var="slp",t=tt).getf()
u10m = pp(file=fi,var="u10m",t=tt).getf()
v10m = pp(file=fi,var="v10m",t=tt).getf()
slp = slp/1E2
contfrac = pp(file=fi,var="contfracATM").getf()
#------------------------------------------------------------------

# Pour tracer des cartes
#------------------------------------------------------------------
p = plot2d()
p.f = slp
p.c = contfrac
p.x = x
p.y = y
p.fmt = "%.2f"
p.vmin=990.
p.vmax=1030.
p.vx = u10m
p.vy = v10m
p.svx = 1
p.svy = 1
p.title = 'Wind velocity and sea level pressure'
p.units = 'm/s and hPa'
# For colors, see https://matplotlib.org/1.4.3/users/colormaps.html
p.colorbar = 'jet'
p.clab = False # contour ON/OFF
p.cfmt = "%.2f" # format contour
p.clev = [0.5]
p.makeshow()
#------------------------------------------------------------------
