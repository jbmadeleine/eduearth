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
parser.add_option('-t','--time',action='append',dest='t',type="string",default=None,help="t axis value. one value; or val1,val2 (computations)")
(opt,args) = parser.parse_args()
# Filename
if len(args) == 0: args = "histhf.nc"
fi=args
# Time
if opt.t is None:
  tt = 1
else:
  tt = opt.t

#zlev = 1009e2 #1st level ~30m
zlev = 999e2 #2nd level ~100m

# Choix des donnees
#------------------------------------------------------------------
#month = 1. # numero du mois
#tt = 86400.*30.*(month+0.5)
windvel,x,y,z,t = pp(file=fi,var="wind10m",t=tt).getfd()
slp = pp(file=fi,var="slp",t=tt).getf()
u10m = pp(file=fi,var="u10m",t=tt).getf()
v10m = pp(file=fi,var="v10m",t=tt).getf()
vitu = pp(file=fi,var="vitu",t=tt,z=zlev).getf()
vitv = pp(file=fi,var="vitv",t=tt,z=zlev).getf()
wind = (vitu**2.+vitv**2.)**0.5
slp = slp/1E2
contfrac = pp(file=fi,var="contfracATM").getf()
#------------------------------------------------------------------

x=np.ndarray.flatten(wind)

# Pour tracer des cartes
#------------------------------------------------------------------
plt.hist(x, range = (0, 25), bins = 25, color = 'yellow',
            edgecolor = 'red')
plt.xlabel('Vitesse du vent (m/s)')
plt.ylabel('Nombre')
plt.title('Distribution du vent')
plt.show()
