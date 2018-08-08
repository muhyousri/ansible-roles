#! /bin/bash
#This is modified to work with apt based distros
#spath=/etc/bareos/bareos-fd.d
#cd $spath
#path1=client/myself.conf
#path22=director/bareos-dir.conf
#path33=messages/Standard.conf
#pass=$(date +%s | sha256sum | base64 | head -c 33)
#read $pass
#name=$1
#echo -e "\n"
#echo -e "Enter the name  of backup Server"
#read name

#read -e $name
#sed -i -e "s/\(Name=\).*/\1$1/" \>>>
#for value in $path1

#do
#URL=http://download.bareos.org/bareos/release/latest/CentOS_6/bareos.repo
#wget -O /etc/yum.repos.d/bareos.repo $URL  > /dev/null 2>&1
#wget http://download.bareos.org/bareos/release/latest/CentOS_6/bareos.repo
#yum clean all > /dev/null 2>&1
#yum repolist > /dev/null 2>&1
#yum install -y > /dev/null 2>&1

DIST=xUbuntu_16.04  
RELEASE=release/latest/ 
URL=http://download.bareos.org/bareos/$RELEASE/$DIST 
 
# add the Bareos repository 
printf "deb $URL /\n" > /etc/apt/sources.list.d/bareos.list > /dev/null  2>&1 
 



# add package key 
wget -q $URL/Release.key -O- | apt-key add - > /dev/null 2>&1

 
# install Bareos packages 
apt-get update  > /dev/null  2>&1
export DEBIAN_FRONTEND=noninteractive
apt-get -y install bareos bareos-database-postgresql > /dev/null 2>&1



spath=/etc/bareos/bareos-fd.d
cd $spath
path1=client/myself.conf
path22=director/bareos-dir.conf
path33=messages/Standard.conf
pass=$(date +%s | sha256sum | base64 | head -c 33)
IP=$( echo `ifconfig eth0 2>/dev/null|awk '/inet/ {print $2}'|sed 's/inet//'`)
name=$(hostname -f)

if [[ -f "$path1" ]]; then

sed -i 's/Name = .*/Name = '$name'/' $path1
sed -i '4i\FDport = 9105\' $path1

else 

echo "there are error in $path1" > /dev/null 2>&1
fi
#cd /etc/bareos/bareos-fd.d/director
#done
#for value in $path2 
#do
if [[ -f "$path22" ]]; then

sed -i 's/Name = .*/Name = 'bdr01-dir'/' $path22
sed -i 's/Password = .*/Password = '$pass'/' $path22

else

echo "there are problem at file"
fi




if [[ -f "$path33" ]]; then

sed -i 's/Name = .*/Name = '$name'/' $path33
#sed -i 's/Director = .*/Name = 'bdr01-dir'/' $path33
sed -i 's/Director = bareos-dir = all, !skipped, !restored /Director = "bdr01-dir = all, !skipped, !restored"/' $path33

else

echo "there are problem at file" > /dev/null 2>&1
fi

csf -a 5.79.85.94 > /dev/null 2>&1
csf -a 94.75.199.75 > /dev/null 2>&1
csf -a 37.220.15.186 > /dev/null 2>&1
csf -r > /dev/null 2>&1
/etc/init.d/bareos-fd restart > /dev/null 2>&1
clear > /dev/null 2>&1
##summary#######
echo $pass



