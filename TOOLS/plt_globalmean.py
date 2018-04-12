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
if len(args) == 0: args = "histday.nc"
fi=args

# Pour l'evolution en un point
#------------------------------------------------------------------
fluxsurf,x,y,z,t = pp(file=fi,var="SWdnSFC",changetime="earth_calendar").getfd()
fluxtop = pp(file=fi,var="SWdnTOA",changetime="earth_calendar").getf()
t2m = pp(file=fi,var="t2m",changetime="earth_calendar").getf()
area = pp(file=fi,var="aire",changetime="earth_calendar").getf()
#------------------------------------------------------------------

lati = np.deg2rad(y[:,0])
weights = np.cos(lati)
fluxtop_zonal = fluxtop.mean(axis=2)
fluxtop_mean = np.average(fluxtop_zonal, axis=1, weights=weights)

#------------------------------------------------------------------
fig = plt.figure()
ax = fig.gca()
ax.set_ylabel("Eclairement moyen (W/m2)")
#ax.set_ylim([402.,404.])
plt.grid()
plt.plot(t,fluxtop_mean,'k')
#plt.legend(('Au sommet 'r"$\bar{I}_{TOA}$",
#  'Direct en surface 'r"$\bar{I}_{direct}$",
#  'Arrivant sur le PV'),
#  loc=(0.53, 0.7))
plt.xticks(rotation=30,ha='right')
plt.subplots_adjust(bottom=0.2,left=0.2)
plt.show()
#------------------------------------------------------------------
