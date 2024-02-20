#!/bin/bash
#Author: Luis Díaz
#Script para implementar la web de paquetes de viajes

repo="bootcamp-devops-2023"
USERID=$(id -u)


if [ "${USERID}" -ne 0 ]; then
    echo -e "Correr con usuario ROOT"
    exit
fi

#Actualizando el SO
echo "===Verificando las ultimas actualizaciones del sistema==="

apt-get update
apt-get upgrade -y

#Verificar que los servicios estén instalados(Apache2, PHP,GIT, MariaDB, Curl)
servicios=("apache2" "php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl" "mariadb-server" "git" "curl")

for servicio in "${servicios[@]}"
do
  if dpkg -s "$servicio" > /dev/null 2>&1; then
    echo "$servicio ya está instalado..."
  else
    echo "$servicio se está instalando..."
    apt-get install -y "$servicio"
    fi
done

#Configurando la base de datos

 mysql -e "
 CREATE DATABASE devopstravel;
 CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
 GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
 FLUSH PRIVILEGES;"

#Configurando la BD
cat > database/devopstravel.sql <<-EOF
<?php
$dbHost     = "localhost"; 
$dbUsername = "codeuser"; 
$dbPassword = ""; 
$dbName     = "devopstravel"; 
$conn = new mysqli($dbHost, $dbUsername, $dbPassword, $dbName); 
if ($conn->connect_error) { 
    die("Connection failed: " . $conn->connect_error); 
}
?>
EOF


#Agregamos datos a la BD
mysql < database/devopstravel.sql

#Iniciando y habilitando los servicios instalados
systemctl start mariadb
systemctl enable mariadb
systemctl start apache2
systemctl enable apache2


if [ -d "$repo" ]; then
    echo -e "La carpeta $repo existe..."
    git pull
else
    git clone https://github.com/roxsross/$repo.git
    mv /var/www/html/index.html /var/www/html/index.html.bkp
    cp -r $repo/* /var/www/html/
fi



#recargando el servicio apache2
systemctl reload apache2

#Modificando el archivo dir.conf
dir_modified="<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
        </IfModule>"

echo "$dir_modified" > /etc/apache2/mods-enabled/dir.conf

curl localhost/info.php

echo "Fin del Script"