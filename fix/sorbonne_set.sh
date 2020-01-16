#! /bin/bash

### in main folder run
### ./fix/upmc_set.exe

safetytest=`echo $PWD | grep -c fix`
if [ $safetytest -ne 0 ]
then
  echo "Ne pas executer ce script dans le dossier fix."
  echo "Executer ce script depuis eduplanet avec la commande:"
  echo "./fix/upmc_set.sh"
  exit
fi

px="proxyweb.upmc.fr"
po="3128"

whereisplanetoplot=$PWD/TOOLS/planetoplot

touch yorgl
echo "[global]" >> yorgl
echo "http-proxy-host = $px" >> yorgl
echo "http-proxy-port = $po" >> yorgl
mkdir -p $HOME/.subversion 
mv $HOME/.subversion/servers $HOME/.subversion/servers.bak
mv yorgl $HOME/.subversion/servers
#cat $HOME/.subversion/servers

touch .wgetrc
echo "use_proxy=on" >> .wgetrc
echo "http_proxy=$px:$po" >> .wgetrc
echo "ftp_proxy=$px:$po" >> .wgetrc
mv -f .wgetrc $HOME/
#cat $HOME/.wgetrc

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


