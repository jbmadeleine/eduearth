#!/bin/bash

ulimit -Ss unlimited

an=clim
####################################################################
# CAREFUL: make sure that the parameters below are the same in
#   install.sh and run.sh
####################################################################
parallel=0
mpi=4
omp=2
machine=local
veget=0
version=20180516.trunk
nz=39
####################################################################

nz=39
comp=0
expname="expnum"

while (($# > 0))
   do
   case $1 in
     "-h") cat <<........fin
    $0 [ -v version ] [ -comp ] -z NB_VERT_LEVELS ] [ -name EXP_NAME ]

    -v       "version" like 20150828.trunk
             see http://www.lmd.jussieu.fr/~lmdz/Distrib/LISMOI.trunk
    -comp    recompile the model, only taking into account changes
    -z       number of vertical levels (39 default)
    -name    name of the experiment (used for directory name)
........fin
     exit ;;
     "-v") version=$2 ; shift ; shift ;;
     "-comp") comp=1 ; shift ;;
     "-z") nz=$2 ; shift ; shift ;;
     "-name") expname=$2 ; shift ; shift ;;
     *) ./run.sh -h ; exit
   esac
done

curdir=$PWD
SIMU=$curdir/LMDZ$version/modipsl/modeles/LMDZ/INIT
mkdir -p $SIMU
cd $SIMU

if [ $parallel = 1 ] ; then
   rungcm="./run_$machine.sh $mpi $omp gcm.e"
   runini="./run_$machine.sh 1 1 ce0l.e"
else
   rungcm="./gcm.e"
   runini="./ce0l.e"
fi

if [ $veget = 0 ] ; then
   VEGET=n
else
   VEGET=y
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

if [ $comp = 1 ] ; then
  echo '###############################################################'
  echo '     Recompiling LMDz'
  echo '###############################################################'
  cd ../
  for mod in gcm ce0l ; do
     ./compile.sh $mod
     if [ ! -f $mod.e ] ; then
        echo Echec pour la compilation de lmdz ; exit
     fi
  done
  cd $SIMU
fi

echo
echo '###############################################################'
echo '     Creating initial state and boundary conditions'
echo '###############################################################'
echo '  in files start.nc, startphy.nc, limit.nc             '
echo 
echo '...............................................................'
echo '  Getting input files from the web                         '
echo '...............................................................'
ln -s ../*.e ../*.sh .
cp ../DEF/*def .

if [ "$an" = "clim" ] ; then
   suf=1x1_clim
else
   suf=360x180_$an
fi

for file in Albedo.nc Relief.nc Rugos.nc landiceref.nc amipbc_sic_$suf.nc amipbc_sst_$suf.nc ; do
   if [ -f $file ] ; then
# If input files are already there, do not download
      echo File $file is there already
   else
      myget Limit/$file
   fi
done
if [ -f ECDYN.nc ] ; then echo ECDYN.nc already there ; else myget Init/ECDYN.nc ; fi 

if [ -f amipbc_sst_$suf.nc ] ;  then
    ln -sf ECDYN.nc ECPHY.nc
    ln -sf amipbc_sic_$suf.nc amipbc_sic_1x1.nc
    ln -sf amipbc_sst_$suf.nc amipbc_sst_1x1.nc
else
    echo Les fichiers n ont pas ete telecharges correctement ; exit
fi

echo
echo '...............................................................'
echo '     Running ce0l.e  (output listing in ce0l.out)              '
echo '...............................................................'
echo "$runini > ce0l.out 2>&1"
$runini > ce0l.out 2>&1

echo
echo '.....................................................'
echo '     Creating a figure for the grid named grid.pdf'
echo '.....................................................'

echo "use grilles_gcm.nc" > tmp.jnl
echo "let rel=if (abs(grille_s-1) gt 0.5) then phis" >> tmp.jnl
echo "shade/pal=land_sea_values rel ; go land" >> tmp.jnl
echo "let deep=if (rel lt 0.1) then rel" >> tmp.jnl
echo "shade/pal=blue/o deep" >> tmp.jnl
echo "quit" >> tmp.jnl

ferret -batch tmp.ps -nojnl -script  tmp.jnl > out.ferret 2>&1
ps2epsi tmp.ps ; epstopdf tmp.ps ; \mv tmp.pdf grille.pdf >>  out.ferret 2>&1

cd ../
zedate=`date --rfc-3339=seconds | sed s+' '+'_'+g | sed s+':'+'-'+g | awk -F '+' '{print $1}'`

simudir=$expname"_"$zedate
mkdir $simudir

if [ $veget != 0 ] ; then

   echo
   echo '...............................................................'
   echo '       Preparing simulations with Orchidee'
   echo '...............................................................'
   echo '   Geting input files from the web for Orchidee                '


   mkdir expnum0 ; cd expnum0
   for file in PFTmap_IPCC_2000.nc cartepente2d_15min.nc \
                     routing.nc lai2D.nc soils_param.nc ; do
      myget Orchidee/$file
   done
   ln -sf PFTmap_IPCC_2000.nc PFTmap.nc

   # Modifying .def files for a first 1-day simulation
   cp -f ../DEF/*def .
   sed -e 's/VEGET=.*.$/VEGET='$VEGET'/' ../DEF/config.def >| config.def
   sed -e 's/nday=.*.$/nday=1/' ../DEF/run.def >| run.def
   sed -e 's/^SECHIBA_restart_in=.*./SECHIBA_restart_in=NONE/' \
                               ../DEF/orchidee.def >| orchidee.def
   ln -s ../INIT/start.nc ../INIT/startphy.nc ../INIT/limit.nc .
   ln -s ../gcm.e ../*sh .

   echo ' NOTICE : To run the model with orchidee, you need to run a first'
   echo ' simulation to create the orchidee initial file'
   echo ' cd expnum0'
   echo   $rungcm' > listing0                           '
   echo 'Then,'

   cd ../$simudir
   ln -s ../expnum0/restart.nc start.nc
   ln -s ../expnum0/restartphy.nc startphy.nc
   ln -s ../expnum0/sechiba_rest_out.nc sechiba_rest_in.nc

else

   cd $simudir
   cp ../INIT/start.nc ../INIT/startphy.nc .

fi


####################################################################
# Preparing a Directory for a first simulation :
####################################################################

cp ../gcm.e ../*.sh .
cp ../DEF/*def .
cp ../INIT/grille.pdf .
sed -e 's/VEGET=.*.$/VEGET='$VEGET'/' ../DEF/config.def >| config.def
sed -e 's/L39.def/L'$nz'.def/' ../DEF/run.def >| run.def 
cp ../INIT/limit.nc .

echo "Running the simulation"
$rungcm | tee listing0 | grep "Date = "

echo "Moving the simulation to main directory"
cd $curdir
mkdir $simudir
mv -n $SIMU/../$simudir/* $simudir/.
rmdir $SIMU/../$simudir

echo "Simulation's results can be found in "$simudir
