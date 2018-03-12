#!/bin/bash

ulimit -Ss unlimited
curdir=$PWD

nx=32
ny=32
nz=39
lmdzonly=0
while getopts "x:y:z:-:" options; do
  case $options in
   x) nx=${OPTARG};;
   y) ny=${OPTARG};;
   z) nz=${OPTARG};;
   -) case $OPTARG in
        # --lmdzonly (without planetoplot)
        lmdzonly) lmdzonly=1;;
        *) echo "Unknown option $OPTARG"
           exit;;
      esac;;
   *) echo "Unknown option"
      exit;;
  esac
done

#############################################################
# 1. Setup
#############################################################

# standards : 96x95x39, 144x142x79

grid_resolution=$nx"x"$ny"x"$nz
version=20171119.trunk
####################################################################
# CAREFUL: make sure that the parameters below are the same in
#   install.sh and run.sh
####################################################################
parallel=0
machine=local
veget=0
####################################################################
rrtm=1

# This could be improved to add parallel capability
echo "Running install_lmdz.sh"
./install_lmdz.sh -d $grid_resolution -v $version -parallel none \
  -bench 0 -veget $veget -nofcm > install_lmdz.log 2>&1

hostname=`hostname`
if [ ${hostname:0:5} = ada33 ] ; then
   machine=X64_ADA
fi

# A function to fetch files either locally or on the internet
function myget { #1st and only argument should be file name
  # Path on local computer where to look for the datafile
  if [ -f /u/lmdz/WWW/LMDZ/pub/3DInputData/$1 ] ; then
    \cp -f -p /u/lmdz/WWW/LMDZ/pub/3DInputData/$1 .
  elif [ -f ~/LMDZ/pub/3DInputData/$1 ] ; then
    ln -s ~/LMDZ/pub/3DInputData/$1 .
  else
    wget http://www.lmd.jussieu.fr/~lmdz/pub/3DInputData/$1
  fi
}

#------------------------------------------------------------
# 1.1 Mode parallele / sequentiel
#------------------------------------------------------------
modipsl=`pwd | sed -n -e 's/modipsl.*.$/modipsl/p'`

if [ $parallel = 1 ] ; then
   opt_compile="-mem -parallel mpi_omp -arch $machine"
else
   opt_compile=""
fi

################################################################################

if [ $veget = 0 ] ; then
   optveget=""
   VEGET=n
else
   optveget="-v orchidee2.0 -cpp ORCHIDEE_NOZ0H"
   VEGET=y
fi

if [ $rrtm = 0 ] ; then
   opt_rrtm=""
else
   opt_rrtm="-rrtm true"
fi

#########################################################################
# Model location
#########################################################################

# Go to LMDz directory
cd $curdir/LMDZ$version/modipsl/modeles/LMDZ
# Create directories to run simulations in /modipsl/modeles/LMDZ
ln -sf ../../../../DEF .

if [ `pwd | grep modipsl` ] ; then
   MODEL=`pwd | sed -e 's/.modipsl/ /' | awk ' { print $1 } '`
   LMDZ=$MODEL/modipsl/modeles/LMDZ
   if [ ! -d $LMDZ ] ; then LMDZ=$MODEL/modipsl/modeles/LMDZ5 ; fi
else
   echo Mettre emplacement du modele a la main
fi
SIMU=`pwd`
if [ ! -f DEF/run.def -o ! -f DEF/physiq.def -o ! -f DEF/gcm.def ] ; then
    echo Il n y a pas de fichier run.def ou physiq.def ou gcm.def dans le
    echo repertoire $SIMU. Vous pouvez en recuperer sur
    echo $LMDZ/DefLists
    exit
fi

echo
echo '#############################################################'
echo 'Model Compilation                                       '
echo '#############################################################'

echo 'Checking the consistency of the compilation and installation'
compilo=`grep COMPIL $LMDZ/arch/arch-local.fcm | awk ' { print $2 } '`
compilo=`basename $compilo`
if [ "$machine" = "local" -a "$compilo" = "mpif90" -a $parallel = 0 ] ; then
    echo You try to work in serial mode while the model was install in parallel
    exit # if you are an expert, you can modify this
fi
if [ "$machine" = "local" -a "$compilo" = "gfortran" -a $parallel = 1 ] ; then
    echo You try to work in parallel mode while the model was install in serial
    exit # if you are an expert, you can modify this
fi

local=`pwd`
cd $LMDZ
echo "./makelmdz -d $grid_resolution $optveget $opt_compile $opt_rrtm \$1" > compile.sh
echo "cp \$1.e $local/" >> compile.sh
chmod +x compile.sh

for mod in gcm ce0l ; do
   ./compile.sh $mod
   if [ ! -f $mod.e ] ; then
      echo Echec pour la compilation de lmdz ; exit
   fi
done

#############################################################
# INSTALLING PLANETOPLOT
#############################################################
if [[ $lmdzonly == 0 ]]; then
  
  echo '#############################################################'
  echo 'Post-processing tools (planetoplot)                          '
  echo '#############################################################'
  mkdir -p $curdir/TOOLS
  cd $curdir/TOOLS
  rm -rf planetoplot
  git clone https://github.com/aymeric-spiga/planetoplot
  rm -rf planets
  git clone https://github.com/aymeric-spiga/planets
  
fi
#############################################################
