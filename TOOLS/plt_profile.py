#! /usr/bin/env python
from ppclass import pp
from optparse import OptionParser ### TBR by argparse
parser = OptionParser()
parser.add_option('-x','--lon',action='append',dest='x',type="string",default=None,help="x axis value. one value; or val1,val2 (computations)")
parser.add_option('-y','--lat',action='append',dest='y',type="string",default=None,help="y axis value. one value; or val1,val2 (computations)")
(opt,args) = parser.parse_args()
# Filename
if len(args) == 0: args = "histmth.nc"
fi=args
# longi
if opt.x is None:
  xlon = 2.
else:
  xlon = opt.x
# lati
if opt.y is None:
  ylat = 48.5
else:
  ylat = opt.y

# define object, file, var
m = pp()
m.file = fi
#m.var = "temp"

# define dimensions
#m.x = "136.,139." # computing over x interval
m.x = xlon # computing over x interval
m.y = ylat # setting a fixed y value
m.z = None # leaving z as a free dimension
#m.t = [6.,9.,12.,15.,18.,21.,24.] # setting 4 fixed t values
m.t = 1. # setting 4 fixed t values

# define settings
#m.superpose = True # superpose 1D plots
m.verbose = True # making the programe verbose
#m.out = "pdf" # output format
#m.colorbar = "spectral" # color cycle according to a color map

# get data and make plot with default settings
#m.getplot()

# get potential temperature at same point. 
# don't plot it. do an operation on it.
vitu = pp()
vitu << m
vitu.var = "vitu"
vitu.get()

vitv = pp()
vitv << m
vitv.var = "vitv"
vitv.get()

# get zfullotential at same point.
# don't plot it. do an operation on it (to get height).
zfull = pp()
zfull << m
zfull.var = "zfull"
zfull.get()
z = zfull/1E3

wind = (vitu**2.+vitv**2.)**0.5

# define potential temperature as a function of height
S = wind.func(z)

# change a few plot settings
for curve in S.p: 
    curve.linestyle = "-"
    curve.marker = ""
S.p[0].swaplab = False
S.p[0].ylabel="Height (km)"
S.p[0].ymin=0.
S.p[0].ymax=10.
S.p[0].xmin=0.
S.p[0].xmax=50.
S.p[0].invert = False
S.p[0].xlabel="Wind"
#S.filename = "meso_profile"
S.colorb = None # come back to default color cycle

# make the plot
S.makeplot()
