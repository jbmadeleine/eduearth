#! /usr/bin/env python
# Computes the irradiance on a tilted solar panel

from ppclass import pp
from ppplot import plot2d
import numpy as np
import scipy.stats
import matplotlib.pyplot as plt
import math as m
import datetime

# pdeclin : latitude du point subsolaire (rad)
# sza : solar zenith angle (rad, =0 at zenith)
# plat : latitude (rad)
# ptime : localtime (0<ptime<1): ptime=0.5 at 12:00 LT
# gamma0 :  sun azimuth (south=0, West =pi/2)
# betaPV : PV angle versus horizontale (rad)
# gammaPV : orientation of the PV (south=0, West=90deg or pi/2)
# muPV : cosine of the angle between PV and sun
# thetaPV : angle between PV and sun

# arguments
from optparse import OptionParser ### TBR by argparse
parser = OptionParser()
parser.add_option('-x','--lon',action='append',dest='x',type="string",default=None,help="x axis value. one value; or val1,val2 (computations)")
parser.add_option('-y','--lat',action='append',dest='y',type="string",default=None,help="y axis value. one value; or val1,val2 (computations)")
parser.add_option('-b','--beta',action='append',dest='b',type="string",default=None,help="y axis value. one value; or val1,val2 (computations)")
parser.add_option('-g','--gamma',action='append',dest='g',type="string",default=None,help="y axis value. one value; or val1,val2 (computations)")
(opt,args) = parser.parse_args()
# Filename
if len(args) == 0: args = "histhf.nc"
fi=args
# longi
if opt.x is None:
  xloc = 2.
else:
  xloc = [float(i) for i in opt.x][0]
# lati
if opt.y is None:
  yloc = 48.5
else:
  yloc = [float(i) for i in opt.y][0]
# betaPV
if opt.b is None:
  betaPV = 45.*m.pi/180.
else:
  betaPV = [float(i) for i in opt.b][0]
# gammaPV
if opt.g is None:
  gammaPV = -9999
else:
  gammaPV = [float(i) for i in opt.g][0]

# Pour l'evolution en un point
#------------------------------------------------------------------

fluxsurf,x,y,z,t = pp(file=fi,var="SWdnSFC",x=xloc,y=yloc,changetime="earth_calendar").getfd()
fluxtop = pp(file=fi,var="SWdnTOA",x=xloc,y=yloc,changetime="earth_calendar").getf()
t2m = pp(file=fi,var="t2m",x=xloc,y=yloc,changetime="earth_calendar").getf()
sza = pp(file=fi,var="sza",x=xloc,y=yloc,changetime="earth_calendar").getf()
#------------------------------------------------------------------
doy = np.array([t[i].timetuple().tm_yday for i in range(0,len(t))])
pdeclin = 23.45*np.sin(360.*(284.+doy)/365.*m.pi/180.)*m.pi/180.

# Compute azimuth of the sun : gamma0 (south=0, West =pi/2)
# --------------------------

sza = sza * m.pi / 180.
plat = yloc * m.pi / 180.
lt = t + datetime.timedelta(hours=xloc/180.*12.)
ptime = np.array([(lt[i].hour+lt[i].minute/60.)/24. for i in range(0,len(t))])
px  = (np.sin(plat)*np.cos(pdeclin)*np.cos(m.pi*(2.*ptime-1.)) - \
  np.cos(plat) * np.sin(pdeclin)) / np.sin(sza)
py  = (np.cos(pdeclin) * np.sin(m.pi*(2.*ptime-1.))) / np.sin(sza)
px[px > 1.] = 1. # px = min(px, 1.)
px[px < -1.] = -1. # px = max(px,-1.)
gamma0 = np.arccos(px)
gamma0[sza < 1.e-3] = 0.
for i in range(0,len(t)):
  if py[i] < 0: gamma0[i] = -gamma0[i]

#   Compute cosine of Angle between solar beams and the normal to the PV 
#   -------------------------------------------------------------

if gammaPV == -9999: gammaPV = gamma0 # sun-tracking

muPV=np.cos(betaPV) * np.cos(sza) \
  + np.sin(betaPV) * np.sin(sza) * np.cos(gammaPV - gamma0)
muPV[muPV < 0.] = 0. # muPV=max(muPV,0.)
thetaPV = np.arccos(muPV)

# Flux calculation 
# ----------------

fluxPV = fluxsurf * np.cos(thetaPV) / np.cos(sza)

# Efficiency dependency to temperature
# ------------------------------------
# Evans-Florschuetz relation
# Coefficients for Mono-Si panel
# Swapnil Dubey et al. / Energy Procedia 33 ( 2013 ) 311 - 321
etaref = 0.15
betaref = 0.0041
tref = 273.15+25.
eta = etaref*(1.-betaref*(t2m-tref))
# Solar panel area
area = 1.
# Compute final power
puissance = eta * fluxPV * area

# Pour l'evolution en un point
#------------------------------------------------------------------
fig = plt.figure()
ax = plt.subplot(211)
#ax = fig.gca()
ax.set_xlabel("Temps")
ax.set_ylabel("Eclairement (W/m2)")
plt.grid()
#plt.plot(t,sza*180./m.pi,'r-')
plt.plot(t,fluxtop,'k')
plt.plot(t,fluxsurf,'b')
plt.plot(t,fluxPV,'r')
plt.legend(('Au sommet 'r"$\bar{I}_{TOA}$",
  'Direct en surface 'r"$\bar{I}_{direct}$",
  'Arrivant sur le PV'),
  loc=(0.53, 0.7))
#------------------------------------------------------------------
ax = plt.subplot(212)
ax.set_xlabel("Temps")
ax.set_ylabel("Puissance surfacique (W/m2)")
plt.plot(t,puissance,'b')
#plt.plot(t,thetaPV*180./m.pi,'b')
#plt.plot(t,sza*180./m.pi,'b')
plt.grid()
plt.show()
#------------------------------------------------------------------
