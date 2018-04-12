from ppclass import pp
from ppplot import plot2d
import numpy as np
import scipy.stats
import matplotlib.pyplot as plt
import math as m
import netCDF4

# arguments
from optparse import OptionParser ### TBR by argparse
parser = OptionParser()
(opt,args) = parser.parse_args()
if len(args) == 0: args = "dynzon.nc"
fi=args

# Choix des donnees
#------------------------------------------------------------------
month = 13 # indice du mois, demarre a zero
day_step = 960 # pas de temps par jour
tt = 86400.*30.*(month+0.5)*day_step*6.

temp,x,y,z,t = pp(file=fi,x=0,t=tt,var="T",verbose=True,kind3d="tzy").getfd()
psi = pp(file=fi,x=0,t=tt,var="psi",verbose=True,kind3d="tzy").getf()
#------------------------------------------------------------------

# Pour tracer des cartes
#------------------------------------------------------------------
p = plot2d()
p.f = psi # psi units = "mega t/s", soit 1E9 kg/s
p.c = temp
p.x = y
p.y = z
p.fmt = "%.2f"
p.vmin=-100.
p.vmax=100.
p.logy = False
p.invert = True
p.title = 'Streamfunction and temperature'
p.units = "$10^9$"'kg/s and K'
# For colors, see https://matplotlib.org/1.4.3/users/colormaps.html
p.colorbar = 'bwr'
p.clab = True # contour ON/OFF
p.cfmt = "%.0f" # format contour
#p.clev = [0.5]
p.makeshow()
#------------------------------------------------------------------
