#! /usr/bin/env python
# Computes the irradiance on a tilted solar panel

from ppclass import pp
from ppplot import plot2d
import numpy as np
import scipy.stats
import matplotlib.pyplot as plt
import math as m
import datetime

# arguments
from optparse import OptionParser ### TBR by argparse
parser = OptionParser()
(opt,args) = parser.parse_args()
if len(args) == 0: args = "histhf.nc"
fi=args

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
plt.plot(t,fluxinc,'b')
plt.plot(t,fluxsurf,'r--')
# Il est possible de decaler en heure locale grace a cette commande
#plt.plot(t-datetime.timedelta(hours=4),fluxsurf,'b')
plt.legend(('Au sommet 'r"$\bar{I}_{TOA}$",
  'Direct en surface 'r"$\bar{I}_{direct}$"),
  loc=(0.53, 0.7))
plt.grid()
plt.show()
#------------------------------------------------------------------
