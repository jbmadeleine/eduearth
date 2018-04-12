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
# psi0 :  sun azimuth (south=0, West =pi/2)
# tetaPV : PV angle versus horizontale (rad)
# psiPV : orientation of the PV (south=0, West=90deg or pi/2)
# muPV : cosine of the angle between PV and sun
# thetaPV : angle between PV and sun

# arguments
from optparse import OptionParser ### TBR by argparse
parser = OptionParser()
(opt,args) = parser.parse_args()
if len(args) == 0: args = "histhf.nc"
fi=args

# Pour l'evolution en un point
#------------------------------------------------------------------
sza,x,y,z,t = pp(file=fi,var="sza",changetime="earth_calendar").getfd()
# We find the latitude of the subsolar point (could be improved!)
sza_minloc = np.array([np.unravel_index(np.argmin(sza[i,:,:]), sza.shape) \
  for i in range(0,len(sza))])
pdeclin = np.array([y[sza_minloc[i,1],sza_minloc[i,2]] \
  for i in range(0,len(sza))])
pdeclin = pdeclin * m.pi / 180.

xloc = 15.
yloc = 30.
fluxsurf,x,y,z,t = pp(file=fi,var="SWdnSFC",x=xloc,y=yloc,changetime="earth_calendar").getfd()
fluxtop = pp(file=fi,var="SWdnTOA",x=xloc,y=yloc,changetime="earth_calendar").getf()
t2m = pp(file=fi,var="t2m",x=xloc,y=yloc,changetime="earth_calendar").getf()
sza = pp(file=fi,var="sza",x=xloc,y=yloc,changetime="earth_calendar").getf()
#------------------------------------------------------------------

# Compute azimuth of the sun : psi0 (south=0, West =pi/2)
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
psi0 = np.arccos(px)
psi0[sza < 1.e-3] = 0.
#if py < 0: psi0=-psi0
for i in range(0,len(t)):
  if py[i] < 0: psi0[i] = -psi0[i]

#   Compute cosine of Angle between solar beams and the normal to the PV 
#   -------------------------------------------------------------
tetaPV = 45.*m.pi/180.
psiPV = 0.*m.pi/180.

muPV=np.cos(tetaPV) * np.cos(sza) \
  + np.sin(tetaPV) * np.sin(sza) * np.cos(psiPV - psi0)
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
puissance = eta * fluxsurf * area

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
ax.set_ylabel("Puissance (W)")
plt.plot(t,puissance,'b')
#plt.plot(t,thetaPV*180./m.pi,'b')
#plt.plot(t,sza*180./m.pi,'b')
plt.grid()
plt.show()
#------------------------------------------------------------------
