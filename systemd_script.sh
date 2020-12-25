yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd tmux vim -y
cd /etc/sysconfig
cat > lookingdump <<EOF
# Конфигурация моего сервиса для аналза логов

# Параметр DUMP это путь до файла каторый мы будем анализаровать
# Параметро WORD это клюсевое слово которое мы будет искать
WORD='Error'
DUMP=/var/log/boot.log
EOF
mkdir /srv/my_scripts/
cd /srv/my_scripts/
cat > lookingdump.sh <<EOF
#!/bin/bash

WORD=\$1
DUMP=\$2
DATE=\`date\`

if grep \$WORD \$DUMP &> /dev/null
then
    logger "\$DATE: I found word, my Lord!"
else
    logger "\$DATA: I let you down mister!"
    exit 0
fi
EOF
chmod 777 lookingdump.sh
cd /etc/systemd/system/
cat > lookingdump.service <<EOF
[Unit]
Description=My first looking dump


[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/lookingdump
ExecStart=/srv/my_scripts/lookingdump.sh $WORD $DUMP
EOF
cat > lookingdump.timer <<EOF
[Unit]
Description=Run looking dump script every 30 second


[Timer]
OnUnitActiveSec=30
Unit=lookingdump.service


[Install]
WantedBy=multi-user.target
EOF
systemctl start lookingdump.timer
systemctl start lookingdump
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '!!!!!!!!Мой Сервис готов!!!!!!!!!!!!!!!!!!!'
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
#cd /etc/sysconfig
#cat > spawn-fcgi <<EOF
#SOCKET=/var/run/php-fcgi.sock
#OPTIONS="-u apache -g apache -s \$SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
#EOF
cd /etc/systemd/system
cat > spawn-fcgi.service <<EOF
[Unit]
Description=Spawn-fcgi startup service by my Otus homework
After=network.target


[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvirenmetnFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process


[Install]
WantedBy=multi-user.target
EOF
systemctl start spawn-fcgi
