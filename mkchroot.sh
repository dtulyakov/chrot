#!/bin/sh
[ -x /home/chroot ] || echo mkdir /home/chroot

echo " В скрипт нужно передавать имя пользователя для которого создаем chroot окружение и ID"
if [ "$1" = "" ] ; then
  echo "    Usage: $0 [ username ] [uid]"
  exit 1
fi

if [ "$2" = "" ] ; then
  echo "    Usage: $0 [ username ] [uid]"
  exit 1
fi

USER=$1

UID=$2
HOME=/home/chroot/${USER}
adduser --uid ${UID} --home ${HOME} --shell /bin/bash ${USER}
GID=`cat /etc/passwd | grep "^$USER:" | cut -d ":" -f 4`

echo " Задаем список бинарей, нужных для работы в chroot"

BINS="
/bin/bash \
/bin/cat \
/bin/chmod \
/bin/cp \
/bin/date \
/bin/df \
/bin/echo \
/bin/ln \
/bin/ls \
/bin/mkdir \
/bin/mv \
/bin/ps \
/bin/pwd \
/bin/rm \
/bin/rmdir \
/bin/sh \
/bin/grep \
/bin/gunzip \
/bin/gzip \
/bin/sed \
/bin/tar \
/bin/uname \
/usr/bin/awk \
/usr/bin/diff \
/usr/bin/du \
/usr/bin/find \
/usr/bin/less \
/usr/bin/sort \
/usr/bin/scp \
/usr/bin/ssh \
/usr/bin/tail \
/usr/bin/touch \
/usr/bin/vi \
/usr/bin/uptime \
"
echo " Создаем структуру каталогов chroot окружения"
mkdir -p $HOME/bin
mkdir -p $HOME/dev
mkdir -p $HOME/etc/ssh
mkdir -p $HOME/home/chroot/$USER/.ssh
mkdir -p $HOME/lib64
mkdir -p $HOME/lib/x86_64-linux-gnu
mkdir -p $HOME/libexec
mkdir -p $HOME/tmp
mkdir -p $HOME/usr/bin
mkdir -p $HOME/usr/local/bin
mkdir -p $HOME/usr/local/etc
mkdir -p $HOME/usr/local/share

echo " Копируем бинарники в chroot окружение"
for item in $BINS;
do
  cp $item $HOME$item
done

echo " Определяем какие библиотеки необходимо скопировать chroot"
for item in $BINS;
do
  ldd $item |awk '{print $3}'|grep "." |grep -v ^\( >> /tmp/libs
done

echo " Копируем библиотеки"
for item in `cat /tmp/libs|sort|uniq`;
do
  cp $item $HOME/lib/
done

echo " Копируем оставшиеся необходимые файлы и библиотеки"
cp /lib64/* $HOME/lib64/
cp /lib/x86_64-linux-gnu/* $HOME/lib/x86_64-linux-gnu/
cp /etc/resolv.conf $HOME/etc/resolv.conf
cp /etc/ssh/ssh_config $HOME/etc/ssh/
cp $HOME/.ssh/* $HOME/home/chroot/$USER/.ssh/
echo " Создадим /etc/motd для пользователя"
echo "Welcome $USER" > $HOME/etc/motd

echo " Теперь /etc/profile для него же"
echo 'export TERMCAP=/etc/termcap' > $HOME/etc/profile
echo 'export PS1="$ "' >> $HOME/etc/profile

echo " /etc/group тоже нужен свой"
cat /etc/group | grep $GID > $HOME/etc/group

echo " Теперь внутри chroot создадим пользователя"
cat /etc/passwd|grep "^$USER:" > $HOME/etc/passwd
cat /etc/shadow|grep "^$USER:" > $HOME/etc/shadow

mknod -m 622 $HOME/dev/console c 5 1
mknod -m 666 $HOME/dev/null c 1 3
mknod -m 666 $HOME/dev/zero c 1 5
mknod -m 666 $HOME/dev/ptmx c 5 2
mknod -m 666 $HOME/dev/tty c 5 0
mknod -m 444 $HOME/dev/random c 1 8
mknod -m 444 $HOME/dev/urandom c 1 9

echo " Выставляем права"
chown root:root $HOME
chmod 755 $HOME
chmod 755 $HOME
chown -R root:root $HOME/bin
chown -R root:root $HOME/etc
chown -R root:root $HOME/home
chown -R $USER:$GID $HOME/home/chroot/$USER
chown -R root:root $HOME/lib
chown -R root:root $HOME/libexec
chown -R root:root $HOME/tmp
chown -R root:root $HOME/usr
chmod 666 $HOME/dev/*
chmod 777 $HOME/tmp
getfacl $HOME/dev/*
echo " Убираем за собой"
rm /tmp/libs
#EOF
