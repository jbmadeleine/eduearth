#! /usr/bin/env python
# Computes the irradiance on a tilted solar panel

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
vmin = 0. ; vmax = 1500.
##################################################

# Coordonnees du point
#------------------------------------------------------------------
xloc = 0.
yloc = 45.

# Variables a charger
#------------------------------------------------------------------
fluxsurf,x,y,z,t = pp(file=fi,var="SWdnSFC",x=xloc,y=yloc,changetime="earth_calendar").getfd()
fluxinc = pp(file=fi,var="SWdnTOA",x=xloc,y=yloc,changetime="earth_calendar").getf()
#------------------------------------------------------------------

# Tracer le graphique
#------------------------------------------------------------------
fig = plt.figure()
ax = fig.gca()
ax.set_xlabel("Temps")
ax.set_ylabel("Eclairement (W/m2)")

plt.grid()
plt.plot(t,fluxinc,'b')
plt.plot(t,fluxsurf,'b--')
plt.show()
#------------------------------------------------------------------
