#! /bin/bash

### in main folder run
### ./fix/user_set.exe

safetytest=`echo $PWD | grep -c fix`
if [ $safetytest -ne 0 ]
then
  echo "Ne pas executer ce script dans le dossier fix."
  echo "Executer ce script depuis eduplanet avec la commande:"
  echo "./fix/user_set.sh"
  exit
fi

whereisplanetoplot=$PWD/TOOLS/planetoplot

num=`grep -c eduearth $HOME/.bashrc`
if [ $num -eq 0 ]
then
  echo 'if [ -f $HOME/.bashrc.eduearth ]; then . $HOME/.bashrc.eduearth; fi' >> $HOME/.bashrc
fi

\rm $HOME/.bashrc.eduearth
echo "export PYTHONPATH=$whereisplanetoplot/modules/:"'$PYTHONPATH' > $HOME/.bashrc.eduearth
echo "export PATH=$whereisplanetoplot/bin/:"'$PATH' >> $HOME/.bashrc.eduearth

whereisplanets=$PWD/TOOLS/planets
echo "export PYTHONPATH=$whereisplanets/:"'$PYTHONPATH' >> $HOME/.bashrc.eduearth
echo "alias ncview='ncview -no_auto_overlay'" >> $HOME/.bashrc.eduearth

echo "!!!!!!!!!!!!!!!!!!!!!!!!"
echo "taper la commande"
echo " source ~/.bashrc"
echo "!!!!!!!!!!!!!!!!!!!!!!!!"

