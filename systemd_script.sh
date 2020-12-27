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
ExecStart=/srv/my_scripts/lookingdump.sh \$WORD \$DUMP
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
cd /etc/sysconfig
cat > spawn-fcgi <<EOF
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s \$SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
EOF
cd /etc/systemd/system
cat > spawn-fcgi.service <<EOF
[Unit]
Description=Spawn-fcgi startup service by my Otus homework
After=network.target


[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process


[Install]
WantedBy=multi-user.target
EOF
systemctl start spawn-fcgi
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '!!!!!!!!Сервис spawn-fcgi готов!!!!!!!!!!!!'
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
cd /etc/systemd/system/
cat > httpd@.service <<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)


[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd \$OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd \$OPTIONS -k graceful
ExecStop=/bin/kill -WINCH \${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true


[Install]
WantedBy=multi-user.target
EOF
cd /etc/sysconfig
cat > httpd-first <<EOF
OPTIONS=-f conf/first.conf
EOF
cat > httpd-second <<EOF
OPTIONS=-f conf/second.conf
EOF
cd /etc/httpd/conf/
cp httpd.conf first.conf && rm -f httpd.conf
cat > second.conf <<EOF
ServerRoot "/etc/httpd"
PidFile /var/run/httpd-second.pid
Listen 8080
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin root@localhost

<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "/var/www/html"

<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"\" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>

EnableSendfile on
EOF
systemctl start httpd@first
systemctl start httpd@second
