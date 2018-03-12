#!/bin/bash

localdir=`pwd`
# Choix du chemin pour la commande rebuild.
rebuild=""
if [ "$rebuild" = "" ] ; then
   rebuild=`pwd | sed -e 's/modipsl.*.\$/modipsl/'`/bin/rebuild
fi

##############################################################
# CAS MONOPROCESSEUR
##############################################################
if [ $1 = 1 -a $2 = 1 ] ; then
cat <<eod>| tmp
# @ job_type = serial
# @ job_name = NOMSIMU
# @ output   = \$(job_name).\$(jobid)
# @ error    = \$(job_name).\$(jobid)
# @ wall_clock_limit = 00:30:00
# @ as_limit = 20.0Gb
# @ queue
ulimit -s unlimited
export OMP_STACKSIZE=800M
cd $localdir
\rm -f hist*
./$3
eod

else
##############################################################
#CAS MULTIPROC
##############################################################
cat <<eod>| tmp
# @ job_type = parallel
# @ job_name = NOMSIMU
# @ output   = \$(job_name).\$(jobid)
# @ error    = \$(job_name).\$(jobid)
# @ total_tasks = $1
# @ parallel_threads = $2
# @ wall_clock_limit = 00:30:00
# @ queue
ulimit -s unlimited
export OMP_STACKSIZE=800M

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/smplocal/pub/NetCDF/4.1.3/lib:/smplocal/pub/HDF5/1.8.9/seq/lib

cd $localdir
\rm -f hist*

poe  ./$3
eod
fi


cat <<eod>> tmp
# Reconstruction des fichiers histoire
for f in \`ls *_0000.nc\` ; do
   file=\`echo \$f | sed -e 's/_0000.nc//'\` ; echo Rebuild for \$file
   if [ -f \$file.nc ] ; then
       echo The \$file.nc file already exists
       echo remove it and run 
       echo \$rebuild -o \$file.nc \${file}_0*.nc
       echo manually
   else
      $rebuild -o \$file.nc \${file}_0*.nc
      if [ -f \$file.nc ] ; then \rm -f \${file}_0*.nc ; fi
   fi
done
eod

llsubmit tmp
