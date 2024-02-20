#!/bin/bash
#Author: Luis Díaz
#Despliegue web agencia de viajes

# 1. Definir variables
repo="bootcamp-devops-2023"
USERID=$(id -u)
servicios=("apache2" "php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl" "mariadb-server" "git" "curl")
rama_git="clase2-linux-bash"
DISCORD="https://discord.com/channels/1209593768395808829/1209593915033002045"

# Colores
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BMAGENTA='\033[1;35m'
BCYAN='\033[1;36m'
BWHITE='\033[1;37m'
NC='\033[0m'

echo "===================== Inicio validación usuario root ==========================="
# 2. Validar que el usuario es ROOT
if [ "${USERID}" -ne 0 ]; then
    echo "Correr script como usuario ROOT..."
    exit 1
fi
echo "======================== Fin validación usuario ================================"
echo "======================== Inicio validación e instalación servicios =============================="
#Instalando todos los servicios
for servicio in "${servicios[@]}"
do
  if dpkg -s "$servicio" > /dev/null 2>&1; then
    echo "$servicio ya está instalado..."
  else
    echo "$servicio se está instalando..."
    apt-get install -y "$servicio"
    fi
done
echo "=====================Fin validación e instalación de servicios ==============================="
echo "===================== Activando los servicios instalados ==============================================="
#Habilitando mariadb
systemctl start mariadb
systemctl enable mariadb
#Habilitando Apache
systemctl start apache2
systemctl enable apache2
echo "======================= Fin activación de servicios =============================================="
echo "===================== Validando / Clonando repositorio GIT ==============================================="
#Validando / Clonando repo Git
if [ -d "$repo" ]; then
    echo "La carpeta $repo existe..."
    git -C $repo pull
else
    git clone -b $rama_git https://github.com/roxsross/$repo.git
    mv /var/www/html/index.html /var/www/html/index.html.bkp
    cp -r $repo/* /var/www/html/
fi
echo "================= Fin validación / Clonación Repo GIT ===================================="
echo "===================== Modificando archivo dir.conf =============================================="
#Modificación archivo dir.conf
echo "<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>" > /etc/apache2/mods-enabled/dir.conf
echo "====================== Fin modificación archivo dir.conf ========================================="
echo "========================Reiniciando el servicio Apache ================================================="
systemctl reload apache2
echo "========================= Fin reinicio apache2 ===================================================="
echo "============================= Configurando base de datos ================================================"
#Configuración DB
mysql -e "
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"
echo "=============================== Fin de configuración de Bd ================================================="
echo "================================== Agredando datos a la BD ============================================"
#agregando datos a la bd
mysql < $repo/app-295devops-travel/database/devopstravel.sql
echo "==================================== Fin agregado de datos a la BD ================================="
echo "=================================== Llamando al archivo config.php ======================================="
cat > config.php <<-EOF
<?php
\$dbHost     = "localhost"; 
\$dbUsername = "codeuser"; 
\$dbPassword = ""; 
\$dbName     = "devopstravel"; 
\$conn = new mysqli(\$dbHost, \$dbUsername, \$dbPassword, \$dbName); 
if (\$conn->connect_error) { 
    die("Connection failed: " . \$conn->connect_error); 
}
?>
EOF
echo "========================================= Fin llamado archivo php =========================================="
echo "===================== Validando / Clonando repositorio GIT ==============================================="
#Validando / Clonando repo Git
if [ -d "$repo" ]; then
    echo "La carpeta $repo existe..."
    git -C $repo pull
else
    git clone -b $rama_git https://github.com/roxsross/$repo.git
    mv /var/www/html/index.html /var/www/html/index.html.bkp
    cp -r $repo/* /var/www/html/
fi
echo "================= Fin validación / Clonación Repo GIT ===================================="

