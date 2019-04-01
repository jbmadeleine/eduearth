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
if len(args) == 0: args = "histmth.nc"
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

# Calcul de la puissance
#------------------------------------------------------------------

# Wmax: puissance nominale (MW)
Wmax = 2E6
# Vin, Vr, Vout: paliers de vitesses (m/s)
Vin = 4.
Vr = 12.
Vout = 25.
# Reol: rayon de l'eolienne (m)
Reol = 90./2. # rayon eolienne (m)

powcoef = 16./27.
rho = 1.225

windv = (vitu**2.+vitv**2.)**0.5

Ecr = (rho*windv**2.)/2.      # Energie cinetique / parcelle air
Fr = m.pi*(Reol**2)*windv*Ecr # Flux energie a travers Eolienne
Pow = powcoef*Fr
Pow = np.where(windv<Vin,0.,Pow)
Pow = np.where(windv>Vr,Wmax,Pow)
Pow = np.where(windv>Vout,0.,Pow)
Pow = np.where(Pow>Wmax,Wmax,Pow)

LFmean = np.mean(Pow/Wmax)*1E2
print "Facteur de charge moyen=%.2e" % (LFmean)

# Pour tracer des cartes
#------------------------------------------------------------------
p = plot2d()
p.f = Pow/1E3
p.c = Pow
p.x = x
p.y = y
p.fmt = "%.2f"
p.vmin=0.
p.vmax=2E3
p.vx = vitu
p.vy = vitv
p.wscale = 10.
p.svx = 1
p.svy = 1
p.title = 'Wind turbine power'
p.units = 'kW'
p.back = 'coast'
p.proj = 'cyl'
# For colors, see https://matplotlib.org/1.4.3/users/colormaps.html
p.colorbar = 'jet'
p.clab = True # contours True/False
#p.cfmt = "%.2f" # format contour
#p.clev = [0.5]
p.makeshow()
#------------------------------------------------------------------
