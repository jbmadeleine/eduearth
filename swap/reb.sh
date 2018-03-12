modipsl=`pwd | sed -n -e 's/modipsl.*.$/modipsl/p'`
file=$1
if [ -d $file.nc ] ; then
    echo The $file.nc file already exists
    echo remove it and run 
    echo $modipsl/bin/rebuild -o $file.nc ${file}_0*.nc
    echo manually
    exit
fi

$modipsl/bin/rebuild -o $file.nc ${file}_0*.nc
if [ -f $file.nc ] ; then rm -f ${file}_0*nc ; fi
