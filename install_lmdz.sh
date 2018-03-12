#!/bin/bash

###########################################################################
# Author : Laurent Fairhead et Frédéric Hourdin
# Usage  : install_lmdz.sh -help
#
# bash installation script of the LMDZ model on a Linux PC.
# the model is downloaded in the following direcory tree
# $MODEL/modipsl/modeles/...
# using the "modipsl" infrastructure created by the "IPSL"
# for coupled (atmosphere/ocean/vegetation/chemistry) climate modeling
# activities.
# Here we only download atmospheric (LMDZ) and vegetation (ORCHIDEE)
# components.
#
# The sources of the models can be found in the "modeles" directory.
# In the present case, LMDZ5, ORCHIDEE and IOIPSL (handling of input-outputs
# using the NetCDF library.
#
# The script downloads various source files (including a version of NetCDF)
# and utilities, compiles the model, and runs a test simulation in a
# munimal configuration.
#
# Prerequisites : pgf90/gfortran, ksh, wget , gunzip, tar, ... 
#
# Modif 18/11/2011
#    changes for option real 8.
#      We comopile with -r8 (or equivalent) and -DNC_DOUBLE for the GCM
#      but with -r4 for netcdf. Variable real must be set to 
#      r4 or r8 at the beginning of the script below.
#
###########################################################################

echo install.sh DEBUT `date`

set -e

################################################################
# Choice of installation options 
################################################################

# A function to fetch files either locally or on the internet
function myget { #1st and only argument should be file name
  # Path on local computer where to look for the datafile
  if [ -f /u/lmdz/WWW/LMDZ/pub/$1 ] ; then
    \cp -f -p /u/lmdz/WWW/LMDZ/pub/$1 .
  elif [ -f ~/LMDZ/pub/$1 ] ; then
    \cp -f -p ~/LMDZ/pub/$1 .
  else
    wget http://www.lmd.jussieu.fr/~lmdz/pub/$1
    #dir=~/LMDZ/pub/`dirname $1` ; mkdir -p $dir ; cp -r `basename $1` $dir
  fi
}


#real=r4
real=r8

# WARNING !!!! For versions before october 2009, use
# install.v2.sh instead of install.sh

#########################################################################
# Valeur par défaut des parametres
#########################################################################
svn=""
version=trunk
getlmdzor=1
netcdf=1   #  1 for automatic installation
           #  0 for no installation
           #  /.../../netcdf-4.0.1 if wanting to link with an already
           #  compiled netcdf library (implies to check option compatibility)
check_linux=1
ioipsl=1
veget=1
bench=1
pclinux=1
compiler=gfortran
SCM=0
# use the old orchidee interface without the calculation of z0h
no_z0h_orc=1
# choose the resolution for the bench runs
# grid_resolution= 32x24x11 or 48x36x19 for tests (test without ORCHIDEE)
#                  96x71x19  standard configuration
grid_resolution=144x142x79
grid_resolution=48x36x19

## parallel can take the values none/mpi/omp/mpi_omp
parallel=mpi_omp
parallel=none
OPT_GPROF=""
OPT_MAKELMDZ=""
MODEL=""

## also compile XIOS? (and more recent NetCDF/HDF5 libraries) Default=no
with_xios="n"
opt_makelmdz_xios=""
## compile_with_fcm=1 : use makelmdz_fcm (1) or makelmdz (0)
compile_with_fcm=1
cosp=0 ; opt_cosp=""

#########################################################################
#  Options interactives
#########################################################################
while (($# > 0))
   do
   case $1 in
     "-h") cat <<........fin
    $0 [ -v version ] [ -r svn_release ]
           [ -parallel PARA ] [ -d GRID_RESOLUTION ] [ -bench 0/1 ]
           [-name LOCAL_MODEL_NAME] [-gprof] [-opt_makelmdz]

    -v       "version" like 20150828.trunk
             see http://www.lmd.jussieu.fr/~lmdz/Distrib/LISMOI.trunk

    -r       "svn_release" : either the svn release number or "last"
    
    -compiler gfortran|ifort|pgf90 (default: gfortran)

    -parallel PARA : can be mpi_omp (mpi with openMP) or none (for sequential)

    -d        GRID_RESOLUTION should be among the available benchs if -bench 1
              among which : 48x36x19, 48x36x39
              if wanting to run a bench simulation in addition to compilation
              default : 48x36x19

    -bench     activating the bench or not (0/1). Default 1

    -name      LOCAL_MODEL_NAME : default = LMDZversion.release

    -netcdf    PATH : full path to an existing installed NetCDF library
               (without -netcdf: also download and install the NetCDF library)  
    
    -veget     ORCHIDEE (0/1)
    -xios      also download and compile the XIOS library
               (requires the NetCDF4-HDF5 library, also installed by default)
               (requires to also have -parallel mpi_omp)

    -gprof     to compile with -pg to enable profiling with gprof

    -cosp      to compile with cosp

    -nofcm     to compile without fcm

    -SCM        install 1D version automatically

    -opt_makelmdz     to call makelmdz or makelmdz_fcm with additional options
........fin
     exit ;;
     "-v") version=$2 ; shift ; shift ;;
     "-r") svn=$2 ; shift ; shift ;;
     "-compiler") compiler=$2
                  case $compiler in
                    "gfortran"|"ifort"|"pgf90") compiler=$2 ; shift ; shift ;;
                    *) echo "Only gfortran , ifort or pgf90 for the compiler option" ; exit
                  esac ;;
     "-d") grid_resolution=$2 ; shift ; shift ;;
     "-gprof") OPT_GPROF="-pg" ; shift ;;
     "-cosp") cosp=1 ; opt_cosp="-cosp true" ; shift ;;
     "-nofcm") compile_with_fcm=0 ; shift ;;
     "-SCM") SCM=1 ; shift ;;
     "-opt_makelmdz") OPT_MAKELMDZ="$2" ; shift ; shift ;;
     "-parallel") parallel=$2
                  case $parallel in
                    "none"|"mpi"|"omp"|"mpi_omp") parallel=$2 ; shift ; shift ;;
                    *) echo Only none mpi omp mpi_omp for the parallel option ; exit
                  esac ;;
     "-bench") bench=$2 ; shift ; shift ;;
     "-name") MODEL=$2 ; shift ; shift ;;
     "-netcdf") netcdf=$2 ; shift ; shift ;;
     "-veget") veget=$2 ; shift ; shift ;;
     "-xios") with_xios="y" ; shift ;;
     *) ./install_lmdz.sh -h ; exit
   esac
done

if [ $parallel = none ] ; then sequential=1 ; else sequential=0 ; fi 

#Chemin pour placer le modele
if [ "$MODEL" = "" ] ; then MODEL=./LMDZ$version$svn ; fi


arch=local


if [ $compiler = g95 ] ; then echo g95 is not supported anymore ; exit ; fi

################################################################
# Specificite des machines
################################################################

hostname=`hostname`
if [ "$pclinux" = 1 ] ; then o_ins_make="-t g95" ; else o_ins_make="" ; fi

case ${hostname:0:5} in

   ada33)   compiler="ifort" ;
            par_comp="ifort" ;
            o_ins_make="-t ada" ;
            make=gmake ;
#            module load intel/2013.0 ;
            arch=X64_ADA ;;

   cicla)   compiler="gfortran" ;
            if [ $parallel != none ] ; then
              module load openmpi/1.4.5-gfortran ;
              root_mpi=$MPI_HOME ;
              path_mpi=$root_mpi/bin ;
              par_comp=${path_mpi}/mpif90 ;
              mpirun=${path_mpi}/mpirun ;
            fi ;
            arch=local  ;
            make=make ;
            o_ins_make="-t g95" ;;
            
   *)       if [ $parallel = none -o -f /usr/bin/mpif90 ] ; then
                path_mpi=`which mpif90 | sed -e s:/mpif90::` ;
                if [ -d /usr/lib64/openmpi ] ; then
                  root_mpi="/usr/lib64/openmpi"
                else
                  root_mpi="/usr"
                fi
            # For Scientifique Linux with gfortran at LMD :
            elif [ -f /usr/lib64/openmpi/1.4.5-gfortran/bin/mpif90 -a $compiler = "gfortran" ] ; then
                path_mpi=/usr/lib64/openmpi/1.4.5-gfortran/bin ;
                root_mpi=/usr/lib64/openmpi/1.4.5-gfortran ;
                export LD_LIBRARY_PATH=${root_mpi}/lib:$LD_LIBRARY_PATH
            # For Scientifique Linux with ifort at LMD :
            elif [ -f /usr/lib64/openmpi/1.4.5-ifort/bin/mpif90 -a $compiler = "ifort" ] ; then
                path_mpi=/usr/lib64/openmpi/1.4.5-ifort/bin ;
                root_mpi=/usr/lib64/openmpi/1.4.5-ifort ;
                export LD_LIBRARY_PATH=${root_mpi}/lib:$LD_LIBRARY_PATH
            # For Scientifique Linux with pgf90 at LMD :
            elif [ -f /usr/lib64/openmpi/1.4.5-ifort/bin/mpif90 -a $compiler = "pgf90" ] ; then
                path_mpi=/usr/lib64/openmpi/1.4.5-pgf/bin ;
                root_mpi=/usr/lib64/openmpi/1.4.5-pgf ;
                export LD_LIBRARY_PATH=${root_mpi}/lib:$LD_LIBRARY_PATH
            else
               echo "Cannot find mpif90" ;
               exit ;
            fi ;
            par_comp=${path_mpi}/mpif90 ;
            mpirun=${path_mpi}/mpirun ;
            arch=local  ;
            make=make ;
            o_ins_make="-t g95"
esac

# Flags for parallelism:
if [ $parallel != none ] ; then
  # MPI_LD are the flags needed for linking with MPI
  MPI_LD="-L${root_mpi}/lib -lmpi"
  if [ "$compiler" = "gfortran" ] ; then
    # MPI_FLAGS are the flags needed for compilation with MPI
    MPI_FLAGS="-fcray-pointer"
    # OMP_FLAGS are the flags needed for compilation with OpenMP
    OMP_FLAGS="-fopenmp -fcray-pointer"
    # OMP_LD are the flags needed for linking with OpenMP
    OMP_LD="-fopenmp"
  elif [ "$compiler" = "ifort" ] ; then
    MPI_FLAGS=""
    OMP_FLAGS="-openmp"
    OMP_LD="-openmp"
  else # pgf90
    MPI_FLAGS=""
    OMP_FLAGS="-mp"
    OMP_LD="-mp"
  fi
fi

#####################################################################
# Test for old gfortran compilers
# If the compiler is too old (older than 4.3.x) we test if the
# temporary gfortran44 patch is available on the computer in which
# case the compiler is changed from gfortran to gfortran44
# Must be aware than parallelism can not be activated in this case
#####################################################################

if [ "$compiler" = "gfortran" ] ; then
   gfortran=gfortran
   gfortranv=`gfortran --version | \
   head -1 | awk ' { print $NF } ' | awk -F. ' { print $1 * 10 + $2 } '`
   if [ $gfortranv -le 43 ] ; then
       echo ERROR : Your gfortran compiler is too old
       echo 'Please choose a new one (ifort) and change the line'
       echo compiler=xxx
       echo in the install.sh script and rerun it
       if [ `which gfortran44 | wc -w` -ne 0 ] ; then
          gfortran=gfortran44
       else
          echo gfotran trop vieux ; exit
       fi
   fi
   compiler=$gfortran
fi
#####################################################################

## if also compiling XIOS, parallel must be mpi_omp
if [ "$with_xios" = "y" -a "$parallel" != "mpi_omp" ] ; then 
  echo "Error, you must set -parallel mpi_omp if you want XIOS"
  exit
fi
if [ "$with_xios" = "y" ] ; then
  opt_makelmdz_xios="-io xios"
fi

echo '################################################################'
echo  Choix des options de compilation
echo '################################################################'

export FC=$compiler
export F90=$compiler
export F77=$compiler
export CPPFLAGS=
OPTIMNC=$OPTIM
BASE_LD="$OPT_GPROF"
OPTPREC="$OPT_GPROF"
ARFLAGS="rs" ; if [ -f /etc/issue ] ; then if [ "`grep -i ubuntu /etc/issue`" != "" ] ; then if [ "`grep -i ubuntu /etc/issue | awk ' { print $2 } ' | cut -d. -f1`" -ge 16 ] ; then ARFLAGS="rU" ; fi ; fi ; fi



if [ "$compiler" = "$gfortran" ] ; then
   OPTIM='-O3'
   OPTDEB="-g3 -Wall -fbounds-check -ffpe-trap=invalid,zero,overflow -O0 -fstack-protector-all -fbacktrace -finit-real=nan"
   OPTDEV="-Wall -fbounds-check"
   fmod='I '
   OPTPREC="$OPTPREC -cpp -ffree-line-length-0"
   if [ $real = r8 ] ; then OPTPREC="$OPTPREC -fdefault-real-8 -DNC_DOUBLE" ; fi
   export F90FLAGS=" -ffree-form $OPTIMNC"
   export FFLAGS=" $OPTIMNC"
   export CC=gcc
   export CXX=g++
   export fpp_flags="-P -C -traditional -ffreestanding"

elif [ $compiler = mpif90 ] ; then
   OPTIM='-O3'
   OPTDEB="-g3 -Wall -fbounds-check -ffpe-trap=invalid,zero,overflow -O0 -fstack-protector-all"
   OPTDEV="-Wall -fbounds-check"
   BASE_LD="$BASE_LD -lblas"
   fmod='I '
   if [ $real = r8 ] ; then OPTPREC="$OPTPREC -fdefault-real-8 -DNC_DOUBLE -fcray-pointer" ; fi
   export F90FLAGS=" -ffree-form $OPTIMNC"
   export FFLAGS=" $OPTIMNC"
   export CC=gcc
   export CXX=g++

elif [ $compiler = pgf90 ] ; then
   OPTIM='-O2 -Mipa -Munroll -Mnoframe -Mautoinline -Mcache_align'
   OPTDEB='-g -Mdclchk -Mbounds -Mchkfpstk -Mchkptr -Minform=inform -Mstandard -Ktrap=fp -traceback'
   OPTDEV='-g -Mbounds -Ktrap=fp -traceback'
   fmod='module '
   if [ $real = r8 ] ; then OPTPREC="$OPTPREC -r8 -DNC_DOUBLE" ; fi
   export CPPFLAGS="-DpgiFortran"
   export CC=pgcc
   export CFLAGS="-O2 -Msignextend"
   export CXX=pgCC
   export CXXFLAGS="-O2 -Msignextend"
   export FFLAGS="-O2 $OPTIMNC"
   export F90FLAGS="-O2 $OPTIMNC"
   compile_with_fcm=1

elif [ $compiler = ifort ] ; then
   OPTIM="-O2 -fp-model strict -ip -align all "
   OPTDEV="-p -g -O2 -traceback -fp-stack-check -ftrapuv -check"
   OPTDEB="-g -no-ftz -traceback -ftrapuv -fp-stack-check -check"
   fmod='module '
   if [ $real = r8 ] ; then OPTPREC="$OPTPREC -real-size 64 -DNC_DOUBLE" ; fi
   export CPP="icc -E"
   export FFLAGS="-O2 -ip -fpic -mcmodel=large"
   export FCFLAGS="-O2 -ip -fpic -mcmodel=large"
   export CC=icc
   export CFLAGS="-O2 -ip -fpic -mcmodel=large"
   export CXX=icpc
   export CXXFLAGS="-O2 -ip -fpic -mcmodel=large"
   compile_with_fcm=1

else
   echo unexpected compiler $compiler ; exit
fi

OPTIMGCM="$OPTIM $OPTPREC"

hostname=`hostname`

##########################################################################
# If installing on know machines such as IBM x3750 (Ada)
# at IDRIS, don't check for available software and don"t install netcdf
if [ ${hostname:0:5} = ada33 ] ; then
  netcdf=0 # no need to recompile netcdf, alreday available
  check_linux=0
  pclinux=0
  ioipsl=1 # no need to recompile ioipsl, already available
  #netcdf="/smplocal/pub/NetCDF/4.1.3"
  compiler="ifort"
  fmod='module '
  if [ $real = r8 ] ; then OPTPREC="$OPTPREC -real-size 64 -DNC_DOUBLE" ; fi
  OPTIM="-O2 -fp-model strict -ip -axAVX,SSE4.2 -align all "
  OPTIMGCM="$OPTIM $OPTPREC"
fi
##########################################################################



mkdir -p $MODEL
echo $MODEL
MODEL=`( cd $MODEL ; pwd )` # to get absolute path, if necessary



# Option -fendian=big is only to be used with ARPEGE1D.
# The -r8 should probably be avoided if running on 32 bit machines
# Option r8 is not mandatory and generates larger executables.
# It is however mandatory if using ARPEGE1D
# Better optimization options might be a better choice (e.g. -O3)


echo '################################################################'
if [ "$check_linux" = 1 ] ; then
echo   Check if required software is available
echo '################################################################'

#### Ehouarn: test if ksh and/or bash are available
use_shell="ksh" # default: use ksh
if [ "`which ksh`" = "" ] ; then
  echo "no ksh ... we will use bash"
  use_shell="bash"
  if [ "`which bash`" = "" ] ; then
    echo "ksh (or bash) needed!! Install it!"
  fi
fi


for logiciel in csh wget tar gzip make $compiler gcc ; do
if [ "`which $logiciel`" = "" ] ; then
echo You must first install $logiciel on your system
exit
fi
done

if [ $pclinux = 1 ] ; then
cd $MODEL
cat <<eod > tt.f90
print*,'coucou'
end
eod
$compiler tt.f90 -o a.out
./a.out >| tt
if [ "`cat tt | sed -e 's/ //g' `" != "coucou" ] ; then
echo problem installing with compiler $compiler ; exit ; fi
\rm tt a.out tt.f90
fi
fi

###########################################################################
if [ $getlmdzor = 1 ] ; then
echo '##########################################################'
echo  Download a slightly modified version of  LMDZ
echo '##########################################################'
cd $MODEL
myget src/modipsl.$version.tar.gz
echo install.sh wget_OK `date`
gunzip modipsl.$version.tar.gz
tar xvf modipsl.$version.tar
\rm modipsl.$version.tar

fi

echo OK1

if [ $netcdf = 1 ] ; then
cd $MODEL
netcdflog=`pwd`/netcdf.log
echo '##########################################################'
echo Compiling the Netcdf library
echo '##########################################################'
echo log file : $netcdflog
if [ "$with_xios" = "n" ] ; then
  # keep it simple
  #wget http://www.lmd.jussieu.fr/~lmdz/Distrib/netcdf-4.0.1.tar.gz
  myget import/netcdf-4.0.1.tar.gz
  gunzip netcdf-4.0.1.tar.gz
  tar xvf netcdf-4.0.1.tar
  \rm -f netcdf-4.0.1.tar

  cd netcdf-4.0.1

  # seds to possibly use gfortran44 obsolete nowdays (Ehouarn: 10/2017)
  #sed -e 's/gfortran/'$gfortran'/g' configure >| tmp ; mv -f tmp configure ; chmod +x configure
  localdir=`pwd -P`
  ./configure --prefix=$localdir --enable-shared --disable-cxx
  #sed -e 's/gfortran/'$gfortran'/g' Makefile >| tmp ; mv -f tmp Makefile
  $make check > $netcdflog 2>&1
  $make install >> $netcdflog 2>&1

  # in case netcdf was compiled in 64bits:
  if [ -d $localdir/lib64 ] && !( [ -d $localdir/lib ] )
  then
    ln -sf lib64 $localdir/lib
  fi
else
  # download and compile hdf5 and netcdf, etc. using the install_netcdf4_hdf5.bash script
  #wget http://www.lmd.jussieu.fr/~lmdz/Distrib/install_netcdf4_hdf5.bash
  myget import/install_netcdf4_hdf5.bash
  chmod u=rwx install_netcdf4_hdf5.bash
  if [ "$compiler" = "gfortran" ] ; then
  ./install_netcdf4_hdf5.bash -prefix $MODEL/netcdf4_hdf5 -CC gcc -FC gfortran -CXX g++ -MPI $root_mpi
  elif [ "$compiler" = "ifort" ] ; then
  ./install_netcdf4_hdf5.bash -prefix $MODEL/netcdf4_hdf5 -CC icc -FC ifort -CXX icpc -MPI $root_mpi
  elif [ "$compiler" = "pgf90" ] ; then
  ./install_netcdf4_hdf5.bash -prefix $MODEL/netcdf4_hdf5 -CC pgcc -FC pgf90 -CXX pgCC -MPI $root_mpi
  else
    echo "unexpected compiler $compiler" ; exit
  fi
fi  # of if [ "$with_xios" = "n" ]
echo install.sh netcdf_OK `date`
fi # of if [ $netcdf = 1 ]


#=======================================================================================
echo OK2 ioipsl=$ioipsl
echo '##########################################################'
echo 'Installing MODIPSL, the installation package manager for the '
echo 'IPSL models and tools'
echo '##########################################################'

if [ $netcdf = 0 -o $netcdf = 1 ] ; then
  if [ "$with_xios" = "y" ] ; then
  ncdfdir=$MODEL/netcdf4_hdf5
  else
  ncdfdir=$MODEL/netcdf-4.0.1
  fi
else
  ncdfdir=$netcdf
fi

if [ $ioipsl = 1 ] ; then
  cd $MODEL/modipsl
  \rm -rf lib/*

  cd util

  cp AA_make.gdef AA_make.orig
  F_C="$compiler -c " ; if [ "$compiler" = "$gfortran" -o "$compiler" = "mpif90" ] ; then F_C="$compiler -c -cpp " ; fi
  if [ "$compiler" = "pgf90" ] ; then F_C="$compiler -c -Mpreprocess" ; fi
  sed -e 's/^\#.*.g95.*.\#.*.$/\#/' AA_make.gdef > tmp
  sed -e "s:F_L = g95:F_L = $compiler:" -e "s:F_C = g95 -c -cpp:F_C = $F_C": \
  -e 's/g95.*.w_w.*.(F_D)/g95      w_w = '"$OPTIMGCM"'/' \
  -e 's:g95.*.NCDF_INC.*.$:g95      NCDF_INC= '"$ncdfdir"'/include:' \
  -e 's:g95.*.NCDF_LIB.*.$:g95      NCDF_LIB= -L'"$ncdfdir"'/lib -lnetcdff -lnetcdf:' \
  -e 's:g95      L_O =:g95      L_O = -Wl,-rpath='"$ncdfdir"'/lib:' \
  -e "s:-fmod=:-$fmod:" -e 's/-fno-second-underscore//' \
  -e 's:#-Q- g95      M_K = gmake:#-Q- g95      M_K = make:' \
  tmp >| AA_make.gdef


# We use lines for g95 even for the other compilers to run ins_make
  if [ "$use_shell" = "ksh" ] ; then
    ./ins_make $o_ins_make
  else # bash
    sed -e s:/bin/ksh:/bin/bash:g ins_make > ins_make.bash
    if [ "`grep ada AA_make.gdef`" = "" ] ; then # Bidouille pour compiler sur ada des vieux modipsl.tar
        \cp -f ~rdzt401/bin/AA_make.gdef .
    fi
    chmod u=rwx ins_make.bash
    ./ins_make.bash $o_ins_make
  fi # of if [ "$use_shell" = "ksh" ]

#=======================================================================================
  cd $MODEL/modipsl/modeles/IOIPSL/src
  ioipsllog=`pwd`/ioipsl.log
  echo '##########################################################'
  echo 'Compiling IOIPSL, the interface library with Netcdf'
  echo '##########################################################'
  echo log file : $ioipsllog

  if [ "$use_shell" = "bash" ] ; then
    cp Makefile Makefile.ksh
    sed -e s:/bin/ksh:/bin/bash:g Makefile.ksh > Makefile
  fi
# if [ "$pclinux" = 1 ] ; then
    # Build IOIPSL modules and library
    $make clean
    $make > $ioipsllog 2>&1
    if [ "$compiler" = "$gfortran" -o "$compiler" = "mpif90" ] ; then # copy module files to lib
      cp -f *.mod ../../../lib
    fi
    # Build IOIPSL tools (ie: "rebuild", if present)
    if [ -f $MODEL/modipsl/modeles/IOIPSL/tools/rebuild ] ; then
      cd $MODEL/modipsl/modeles/IOIPSL/tools
      # adapt Makefile & rebuild script if in bash
      if [ "$use_shell" = "bash" ] ; then
        cp Makefile Makefile.ksh
        sed -e s:/bin/ksh:/bin/bash:g Makefile.ksh > Makefile
        cp rebuild rebuild.ksh
        sed -e 's:/bin/ksh:/bin/bash:g' \
            -e 's:print -u2:echo:g' \
            -e 's:print:echo:g' rebuild.ksh > rebuild
      fi
      $make clean
      $make > $ioipsllog 2>&1
    fi
# fi # of if [ "$pclinux" = 1 ] 

else # of if [ $ioipsl = 1 ]
  if [ ${hostname:0:5} = ada33 ] ; then
    cd $MODEL/modipsl
    cd util

    cp AA_make.gdef AA_make.orig
    sed -e 's/^\#.*.g95.*.\#.*.$/\#/' AA_make.gdef > tmp
    sed -e "s:F_L = g95:F_L = $compiler:" -e "s:F_C = g95 -c:F_C = $compiler -c": \
    -e 's/g95.*.w_w.*.(F_D)/g95      w_w = '"$OPTIMGCM"'/' \
    -e 's:g95.*.NCDF_INC.*.$:g95      NCDF_INC= -I/smplocal/pub/HDF5/1.8.9/seq/include -I/smplocal/pub/NetCDF/4.1.3/include:' \
    -e 's:g95.*.NCDF_LIB.*.$:g95      NCDF_LIB= -L/smplocal/pub/NetCDF/4.1.3/lib -lnetcdff -lnetcdf:' \
    -e "s:-fmod=:-$fmod:" -e 's/-fno-second-underscore//' \
    -e 's:#-Q- g95      M_K = gmake:#-Q- g95      M_K = make:' \
    tmp >| AA_make.gdef

    ./ins_make $o_ins_make # We use lines for g95 even for the other compilers

    # on Ada, IOIPSL is already installed in ~rpsl035/IOIPSL_PLUS
    # so link it to current settings
    cd $MODEL/modipsl/modeles/
    \rm -r -f IOIPSL
    ln -s ~rpsl035/IOIPSL_PLUS IOIPSL
    cd ..
    ln -s ~rpsl035/IOIPSL_PLUS/modipsl_Tagv2_2_3/bin/* bin/
    ln -s ~rpsl035/IOIPSL_PLUS/modipsl_Tagv2_2_3/lib/* lib/

  fi # of if [ ${hostname:0:5} = ada33 ]
  echo install.sh ioipsl_OK `date`
fi # of if [ $ioipsl = 1 ]
# Saving ioipsl lib for possible parallel compile
  cd $MODEL/modipsl
  tar cf ioipsl.tar lib/ bin/

#===========================================================================
if [ "$with_xios" = "y" ] ; then
  echo '##########################################################'
  echo 'Compiling XIOS'
  echo '##########################################################'
  cd $MODEL/modipsl/modeles
  #wget http://www.lmd.jussieu.fr/~lmdz/Distrib/install_xios.bash
  myget import/install_xios.bash
  chmod u=rwx install_xios.bash
  if [ ${hostname:0:5} = ada33 ] ; then
    ./install_xios.bash \
    -prefix /workgpfs/rech/gzi/rgzi027/LMDZ20180221.trunk/modipsl/modeles \
    -netcdf /smplocal/pub/NetCDF/4.1.3/mpi -hdf5 /smplocal/pub/HDF5/1.8.9/par \
    -MPI /smplocal/intel/compilers_and_libraries_2017.2.174/linux/mpi/intel64/ \
    -arch X64_ADA
   else
     ./install_xios.bash -prefix $MODEL/modipsl/modeles \
                      -netcdf ${ncdfdir} -hdf5 ${ncdfdir} \
                      -MPI $root_mpi -arch $arch
   fi

fi

#============================================================================
veget_version="false"
if [ "$veget" = 1 ] ; then
  cd $MODEL/modipsl/modeles/ORCHIDEE
  orchideelog=`pwd`/orchidee.log
  echo '########################################################'
  echo 'Compiling ORCHIDEE, the continental surfaces model '
  echo '########################################################'
  echo log file : $orchideelog
  export ORCHPATH=`pwd`
  if [ -d tools ] ; then
     orchidee_rev=2247 
     veget_version=orchidee2.0
      cd arch 
      sed -e s:"%COMPILER        .*.$":"%COMPILER            $compiler":1 \
     -e s:"%LINK            .*.$":"%LINK                $compiler":1 \
     -e s:"%FPP_FLAGS       .*.$":"%FPP_FLAGS           $fpp_flags":1 \
     -e s:"%PROD_FFLAGS     .*.$":"%PROD_FFLAGS         $OPTIM":1 \
     -e s:"%DEV_FFLAGS      .*.$":"%DEV_FFLAGS          $OPTDEV":1 \
     -e s:"%DEBUG_FFLAGS    .*.$":"%DEBUG_FFLAGS        $OPTDEB":1 \
     -e s:"%BASE_FFLAGS     .*.$":"%BASE_FFLAGS         $OPTPREC":1 \
     -e s:"%BASE_LD         .*.$":"%BASE_LD             $BASE_LD":1 \
     -e s:"%ARFLAGS         .*.$":"%ARFLAGS             $ARFLAGS":1 \
     arch-gfortran.fcm > arch-local.fcm
     echo "NETCDF_LIBDIR=\"-L${ncdfdir}/lib -lnetcdff -lnetcdf\"" > arch-local.path
     echo "NETCDF_INCDIR=${ncdfdir}/include" >> arch-local.path
     echo "IOIPSL_INCDIR=$ORCHPATH/../../lib" >> arch-local.path
     echo "IOIPSL_LIBDIR=$ORCHPATH/../../lib" >> arch-local.path
     cd ../ 
# compiling ORCHIDEE sequential mode
     ./makeorchidee_fcm -j 8 -noxios -prod -parallel none -arch $arch > $orchideelog 2>&1
     echo ./makeorchidee_fcm -j 8 -noxios -prod -parallel none -arch $arch
     echo Fin de la premiere compilation orchidee ; pwd
  else
     if [ -d src_parallel ] ; then
       liste_src="parallel parameters global stomate sechiba driver"
       veget_version=orchidee2.0
     else
       # Obsolete, for ORCHIDEE_beton only
       liste_src="parameters stomate sechiba "
       # A trick to compile ORCHIDEE depending on if we are using real*4 or real*8
       cd src_parameters ; \cp reqdprec.$real reqdprec.f90 ; cd ..
       veget_version=orchidee1.9
     fi
     for d in $liste_src ; do src_d=src_$d
        echo src_d $src_d
        echo ls ; ls
        if [ ! -d $src_d ] ; then echo Problem orchidee : no $src_d ; exit ; fi
        cd $src_d ; \rm -f *.mod make ; $make clean
        $make > $orchideelog 2>&1 ; if [ "$compiler" = "$gfortran" -o "$compiler" = "mpif90" ] ; then cp -f *.mod ../../../lib ; fi
        cd ..
     done
  fi
  echo install.sh orchidee_OK `date`
fi # of if [ "$veget" = 1 ]

#============================================================================
# Ehouarn: it may be directory LMDZ4 or LMDZ5 depending on tar file...
if [ -d $MODEL/modipsl/modeles/LMD* ] ; then
  echo '##########################################################'
  echo 'Compiling LMDZ'
  echo '##########################################################'
  cd $MODEL/modipsl/modeles/LMD*
  LMDZPATH=`pwd`
else
  echo "ERROR: No LMD* directory !!!"
  exit
fi

###########################################################
# For those who want to use fcm to compile via :
#  makelmdz_fcm -arch local .....
############################################################

if [ "$pclinux" = "1" ] ; then

# create local 'arch' files (if on Linux PC):
cd arch
# arch-local.path file
echo "NETCDF_LIBDIR=\"-L${ncdfdir}/lib -lnetcdff -lnetcdf\"" > arch-local.path
echo "NETCDF_INCDIR=-I${ncdfdir}/include" >> arch-local.path
echo 'IOIPSL_INCDIR=$LMDGCM/../../lib' >> arch-local.path
echo 'IOIPSL_LIBDIR=$LMDGCM/../../lib' >> arch-local.path
echo 'XIOS_INCDIR=$LMDGCM/../XIOS/inc' >> arch-local.path
echo 'XIOS_LIBDIR=$LMDGCM/../XIOS/lib' >> arch-local.path
echo 'ORCH_INCDIR=$LMDGCM/../../lib' >> arch-local.path
echo 'ORCH_LIBDIR=$LMDGCM/../../lib' >> arch-local.path

BASE_LD="$BASE_LD -Wl,-rpath=${ncdfdir}/lib"
# arch-local.fcm file (adapted from arch-linux-32bit.fcm)

if [ $real = r8 ] ; then FPP_DEF=NC_DOUBLE ; else FPP_DEF="" ; fi
sed -e s:"%COMPILER        .*.$":"%COMPILER            $compiler":1 \
    -e s:"%LINK            .*.$":"%LINK                $compiler":1 \
    -e s:"%PROD_FFLAGS     .*.$":"%PROD_FFLAGS         $OPTIM":1 \
    -e s:"%DEV_FFLAGS      .*.$":"%DEV_FFLAGS          $OPTDEV":1 \
    -e s:"%DEBUG_FFLAGS    .*.$":"%DEBUG_FFLAGS        $OPTDEB":1 \
    -e s:"%BASE_FFLAGS     .*.$":"%BASE_FFLAGS         $OPTPREC":1 \
    -e s:"%FPP_DEF         .*.$":"%FPP_DEF             $FPP_DEF":1 \
    -e s:"%BASE_LD         .*.$":"%BASE_LD             $BASE_LD":1 \
    -e s:"%ARFLAGS         .*.$":"%ARFLAGS             $ARFLAGS":1 \
    arch-linux-32bit.fcm > arch-local.fcm

cd ..
### Adapt "bld.cfg" (add the shell):
whereisthatshell=$(which ${use_shell})
echo "bld::tool::SHELL   $whereisthatshell" >> bld.cfg

fi # of if [ "$pclinux" = 1 ]


cd $MODEL/modipsl/modeles/LMDZ*
lmdzlog=`pwd`/lmdz.log

##################################################################
# Possibly update LMDZ if a specific svn release is requested
##################################################################

if [ "$svn" = "last" ] ; then svnopt="" ; else svnopt="-r $svn" ; fi
if [ "$svn" != "" ] ; then set +e ; svn upgrade ; set -e ; svn update $svnopt ; fi

echo '##################################################################'
echo Compile LMDZ
echo '##################################################################'
echo log file : $lmdzlog

echo install.sh avant_compilation `date`
if [ $compile_with_fcm = 1 ] ; then makelmdz="makelmdz_fcm -arch $arch -j 8" ; else makelmdz="makelmdz -arch $arch" ; fi

# use the orchidee interface that has no z0h
if [ "$veget" = 1 ] && [ "$no_z0h_orc" = 1 ] ; then
veget_version="$veget_version -cpp ORCHIDEE_NOZ0H"
fi

# sequential compilation and bench
if [ "$sequential" = 1 ] ; then
echo "./$makelmdz $OPT_MAKELMDZ -rrtm false $opt_cosp -d ${grid_resolution} -v $veget_version gcm " >> compile.sh
chmod +x ./compile.sh ; ./compile.sh > $lmdzlog 2>&1
echo install.sh apres_compilation `date`


fi # fin sequential



# compiling in parallel mode
if [ $parallel != "none" ] ; then
  echo '##########################################################'
  echo ' Parallel compile '
  echo '##########################################################'
  # saving the sequential libs and binaries
  cd $MODEL/modipsl
  tar cf sequential.tar bin/ lib/
  \rm -rf bin/ lib/
  tar xf ioipsl.tar
  # 
  # Orchidee
  #
  cd $ORCHPATH
  if [ -d src_parallel ] ; then
     cd arch
     sed  \
     -e s:"%COMPILER.*.$":"%COMPILER            $par_comp":1 \
     -e s:"%LINK.*.$":"%LINK                $par_comp":1 \
     -e s:"%MPI_FFLAG.*.$":"%MPI_FFLAGS          $MPI_FLAGS":1 \
     -e s:"%OMP_FFLAG.*.$":"%OMP_FFLAGS          $OMP_FLAGS":1 \
     -e s:"%MPI_LD.*.$":"%MPI_LD              $MPI_LD":1 \
     -e s:"%OMP_LD.*.$":"%OMP_LD              $OMP_LD":1 \
     arch-local.fcm > tmp.fcm

     mv tmp.fcm arch-local.fcm
     cd ../
     echo compiling ORCHIDEE parallel mode
     echo logfile $orchideelog
     ./makeorchidee_fcm -j 8 -clean -noxios -prod -parallel $parallel -arch $arch > $orchideelog 2>&1
     ./makeorchidee_fcm -j 8 -noxios -prod -parallel $parallel -arch $arch >> $orchideelog 2>&1
     echo ./makeorchidee_fcm -j 8 -clean -noxios -prod -parallel $parallel -arch $arch
     echo ./makeorchidee_fcm -j 8 -noxios -prod -parallel $parallel -arch $arch
  else
    echo '##########################################################'
    echo ' Orchidee version too old                                 '
    echo ' Please update to new version                             '
    echo '##########################################################'
    exit
  fi # of if [ -d src_parallel ]
  # LMDZ
  cd $LMDZPATH
  if [ $arch = local ] ; then
    cd arch
    sed -e s:"%COMPILER.*.$":"%COMPILER            $par_comp":1 \
    -e s:"%LINK.*.$":"%LINK                $par_comp":1 \
    -e s:"%MPI_FFLAG.*.$":"%MPI_FFLAGS          $MPI_FLAGS":1 \
    -e s:"%OMP_FFLAG.*.$":"%OMP_FFLAGS          $OMP_FLAGS":1 \
    -e s:"%ARFLAGS.*.$":"%ARFLAGS          $ARFLAGS":1 \
    -e s@"%BASE_LD.*.$"@"%BASE_LD             -Wl,-rpath=${root_mpi}/lib:${ncdfdir}/lib"@1 \
    -e s:"%MPI_LD.*.$":"%MPI_LD              $MPI_LD":1 \
    -e s:"%OMP_LD.*.$":"%OMP_LD              $OMP_LD":1 \
    arch-local.fcm > tmp.fcm
    mv tmp.fcm arch-local.fcm
    cd ../
  fi
  rm -f compile.sh
  if [ ${hostname:0:5} = ada33 ] ; then echo "module load intel/2013.0" > compile.sh ; fi
  echo resol=${grid_resolution} >> compile.sh
  echo ./$makelmdz $OPT_MAKELMDZ -rrtm false $opt_cosp $opt_makelmdz_xios -d \$resol -v $veget_version -mem -parallel $parallel gcm >> compile.sh
  chmod +x ./compile.sh ; ./compile.sh > $lmdzlog 2>&1

  echo "Compilation finished"
  
fi # of if [ $parallel != "none" ]

echo LLLLLLLLLLLLLLLLLLLLLLLLLLL
if [ "$gfortran" = "gfortran44" ] ; then
    echo Your gfortran compiler was too old so that the model was automatically
    echo compiled with gfortran44 instead. It can not be used in parallel mode.
    echo You can change the compiler at the begining of the install.sh
    echo script and reinstall.
fi

##################################################################
# Verification du succes de la compilation
##################################################################

# Recherche de l'executable dont le nom a change au fil du temps ...
gcm=""
for exe in gcm.e bin/gcm_${grid_resolution}_phylmd_seq_orch.e bin/gcm_${grid_resolution}_phylmd_seq.e bin/gcm_${grid_resolution}_phylmd_para_mem_orch.e ; do
   if [ -f $exe ] ; then gcm=$exe ; fi
done

if [ "$gcm" = "" ] ; then
   echo 'Compilation failed !!'
   # Ehouarn : temporary, do not exit and let job finish (to set up bench case)
   #exit
   set +e
else
   echo '##########################################################'
   echo 'Compilation successfull !! '
   echo '##########################################################'
   echo The executable is $gcm
fi

##################################################################
# Below, we run a benchmark test (if bench=0)
##################################################################

if [ $bench != 0 ] ; then

echo '##########################################################'
echo ' Running a test run '
echo '##########################################################'

\rm -rf BENCH${grid_resolution}
bench=bench_lmdz_${grid_resolution}
echo install.sh avant_chargement_bench  `date`
#wget http://www.lmd.jussieu.fr/~lmdz/Distrib/$bench.tar.gz
myget 3DBenchs/$bench.tar.gz
echo install.sh after bench download  `date`
tar xvf $bench.tar.gz

if [ "$with_xios" = "y" ] ; then
  cd BENCH${grid_resolution}
  cp ../DefLists/iodef.xml .
  cp ../DefLists/context_lmdz.xml .
  cp ../DefLists/field_def_lmdz.xml .
  cp ../DefLists/file_def_hist*xml .
  # adapt iodef.xml to use attached mode
  sed -e 's@"using_server" type="bool">true@"using_server" type="bool">false@' iodef.xml > tmp
  \mv -f tmp iodef.xml
  # and convert all the enabled="_AUTO_" (for libIGCM) to enabled=.FALSE.
  # except for histday
  for histfile in file_def_hist*xml
  do
    if [ "$histfile" = "file_def_histday_lmdz.xml" ] ; then
    sed -e 's@enabled="_AUTO_"@type="one_file" enabled=".TRUE."@' $histfile > tmp ; \mv -f tmp $histfile
    else
    sed -e 's@enabled="_AUTO_"@type="one_file" enabled=".FALSE."@' $histfile > tmp ; \mv -f tmp $histfile
    fi
  done
  # and add option "ok_all_xml=y" in config.def
  echo "### XIOS outputs" >> config.def
  echo 'ok_all_xml=.true.' >> config.def
  cd ..
fi

cp $gcm BENCH${grid_resolution}/gcm.e

cd BENCH${grid_resolution}
# On cree le fichier bench.sh au besoin
# Dans le cas 48x36x39 le bench.sh existe deja en parallele

if [ "$grid_resolution" = "48x36x39" ] ; then
   echo On ne touche pas au bench.sh
   # But we have to adapt "run_local.sh" for $mpirun
   sed -e "s@mpirun@$mpirun@g" run_local.sh > tmp
   mv -f tmp run_local.sh
   chmod u=rwx run_local.sh
elif [ "${parallel:0:3}" = "mpi" ] ; then
   # Lancement avec deux procs mpi et 2 openMP
   echo "export OMP_STACKSIZE=800M" > bench.sh
   if [ "${parallel:4:3}" = "omp" ] ; then
     echo "export OMP_NUM_THREADS=2" >> bench.sh
   fi
   echo "ulimit -s unlimited" >> bench.sh
   echo "$mpirun -np 2 gcm.e > listing  2>&1" >> bench.sh
else
   echo "./gcm.e > listing  2>&1" > bench.sh
fi
echo EXECUTION DU BENCH
set +e
date ; ./bench.sh > out.bench 2>&1 ; date
set -e
tail listing


echo '##########################################################'
echo 'Simulation finished in' `pwd`
   echo 'You have compiled with:'
   cat ../compile.sh
if [ $parallel = "none" ] ; then
  echo 'You may re-run it with : cd ' `pwd` ' ; gcm.e'
  echo 'or ./bench.sh'
else
  echo 'You may re-run it with : '
  echo 'cd ' `pwd` '; ./bench.sh'
  echo 'ulimit -s unlimited'
  echo 'export OMP_NUM_THREADS=2'
  echo 'export OMP_STACKSIZE=800M'
  echo "$mpirun -np 2 gcm.e "
fi
echo '##########################################################'

fi


#################################################################
# Installation eventuelle du 1D
#################################################################

if [ $SCM = 1 ] ; then
cd $MODEL
#wget http://www.lmd.jussieu.fr/~lmdz/Distrib/1D.tar.gz
myget 1D/1D.tar.gz
tar xvf 1D.tar.gz
cd 1D
./run.sh
fi
