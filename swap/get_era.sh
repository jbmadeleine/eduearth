#!/bin/bash

#set -vx

#mkdir GUIDAGE
mkdir -p GUIDAGE
cd GUIDAGE
ln -s ../INITIAL/grilles_gcm.nc .

lmax=120 # on devrait pouvoir aller jusqu'a 124 mais ca ne marche pas ...

dirrea=./
path_erai=ERAI/NETCDF/GLOBAL_075/4xdaily/AN_PL/2011
file_erai=201101.aphei.GLOBAL_075

mainrea=3DInputData/ReAnalyses
lmdzpub=~/LMDZ/pub/$mainrea
www=http://www.lmd.jussieu.fr/~lmdz/pub/$mainrea

# A function to fetch files either locally or on the internet
function myget { #1st and only argument should be file name
  # Path on local computer where to look for the datafile
  if [ -f /u/lmdz/WWW/LMDZ/pub/$1 ] ; then
    \cp -f -p /u/lmdz/WWW/LMDZ/pub/$1 .
  elif [ -f ~/LMDZ/pub/$1 ] ; then
    \cp -f -p ~/LMDZ/pub/$1 .
  else
    wget http://www.lmd.jussieu.fr/~lmdz/pub/$1
    dir=~/LMDZ/pub/`dirname $1` ; mkdir -p $dir ; cp -r `basename $1` $dir
  fi
}

for var in u v ; do
path_erai=ERAI/NETCDF/GLOBAL_075/4xdaily/AN_PL/2011
file_erai=201101.aphei.GLOBAL_075
file=$var.$file_erai.nc
echo myget $mainrea/$path_erai/$file
myget $mainrea/$path_erai/$file
done

# Expert : get other months or years throug dods
#    dirrea=http://dodsp.idris.fr/cgi-bin/nph-dods/rpsl500
# OpenDAP link
#     dirrea=https://prodn.idris.fr/thredds/dodsC/ipsl_public/rpsl500

cat <<eod>| tmp.jnl
set memory/size=50
use "./grilles_gcm.nc"
!use "$dirrea/$path_erai/u.$file_erai.nc"
!use "$dirrea/$path_erai/v.$file_erai.nc"
use "./u.$file_erai.nc"
use "./v.$file_erai.nc"

let uwnd=u
let vwnd=v

define axis/t=1-jan-2011:31-jan-2011:6/units=hours thour
define grid/like=uwnd[d=2]/x=grille_u[d=1]/y=grille_u[d=1] grille_u
define grid/like=vwnd[d=3]/x=grille_v[d=1]/y=grille_v[d=1] grille_v
define grid/like=uwnd[d=2]/x=grille_v[d=1]/y=grille_u[d=1] grille_T

save/clobber/file=u.nc uwnd[d=2,g=grille_u,i=1:49,j=1:37,l=1,gt=thour@asn]
repeat/l=1:$lmax save/file="u.nc"/append uwnd[d=2,g=grille_u,i=1:49,j=1:37,gt=thour@asn]

save/clobber/file=v.nc vwnd[d=3,g=grille_v,i=1:49,j=1:36,l=1,gt=thour@asn]
repeat/l=1:$lmax save/file="v.nc"/append vwnd[d=3,g=grille_v,i=1:49,j=1:36,gt=thour@asn]

eod

ferret -nojnl <<eod
go tmp.jnl
quit
eod
#ferret -batch -script tmp.jnl

echo Vous pouvez aussi recuperer les scripts plus automatiques sur
echo svn co http://forge.ipsl.jussieu.fr/igcmg/svn/CONFIG/LMDZOR/branches/LMDZOR_v4/CREATE/SCRIPT
echo et modifier dans SCRIPT/interp_from_era.ksh .
echo 'indir=..'
echo 'gridfile=.../grilles_gcm.nc'
echo 'varlist="u v" ( les variables a interpoler ) '
echo 'outdir=..'
echo 'first_year=2011'
echo 'last_year=2011'
echo 'rundir=.'
