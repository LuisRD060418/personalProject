#!/bin/bash
#Author: Luis Díaz
#Implementación devopsTravel

#Declarando mis variables
REPO="bootcamp-devops-2023"
BRANCH="clase2-linux-bash"
USERID=$(id -u)
DISCORD="https://discord.com/api/webhooks/1209613138786517042/0_qaSlOZOiPMmuhICIC52NRbUocyHcLKldRLbi3ix0b3W84nMDttARyJ-EqZ9uqlzadE"
SERVICIOS=("apache2" "php" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" "mariadb-server" "curl")

# Colores
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BMAGENTA='\033[1;35m'
BCYAN='\033[1;36m'
BWHITE='\033[1;37m'
NC='\033[0m'

#Validamos usuario ROOT

echo -e "\n${BBLUE}Validando que el usuario sea ROOT..${NC}"

if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${BRED}Usar usuario ROOT.${NC}"
    exit
elif [ -z "${PASSDB}" ]; then
    echo -e "\n${BRED}La variable "PASSDB" no está definida.${NC}"
    exit
fi
sleep 1

#Actualizando el servidor

echo -e "\n${BYELLOW}Actualizando el servidor....${NC}"
apt-get update
echo -e "\n${BGREEN}Actualizando el servidor...${NC}"
sleep 1
#Validando e instalando GIT

echo -e "\n${BYELLOW}Validando GIT...${NC}"

if dpkg -s git > /dev/null 2>&1; then
    echo -e "\n${BGREEN}Git ya está instalado..${NC}"
else
    echo -e "\n${BYELLOW}Instalando GIT...${NC}"
    apt install -y git
    echo -e "\${BGREEN}Git fue instalado correctamente...${NC}"
fi
sleep 1
#validando instalación de servicioc WEB LAMP

echo -e "\n${BBLUE}Verificando e instalando servicios web...${NC}"

for SERVICIOS in "${SERVICIOS[@]}"
do
  if dpkg -s "$SERVICIOS" > /dev/null 2>&1; then
    echo "${BGREEN}$SERVICIOS ya está instalado...${NC}"
  else
    echo "\n${BGREEN}$SERVICIOS se está instalando...${NC}"
    apt-get install -y "$SERVICIOS"
    fi
done
sleep 1
#Habilitando los servicios

echo -e "\n${BYELLOW}Habilitando servicios...${NC}"

systemctl start apache2
systemctl enable apache2

systemctl start mariadb
systemctl enable mariadb

echo -e "\n${BGREEN}Servicios Habilitador..${NC}"

#Configurando la Base de Datos

echo -e "\n${BYELLOW}Configurando la base de datos...${NC}"

MYSQL_COMMAND="mysql -e \"CREATE DATABASE IF NOT EXISTS devopstravel; \
           CREATE USER IF NOT EXISTS 'codeuser'@'localhost' IDENTIFIED BY '${PASSDB}'; \
           GRANT ALL PRIVILEGES ON devopstravel.* TO 'codeuser'@'localhost'; \
           FLUSH PRIVILEGES;\""

if eval $MYSQL_COMMAND; then
    echo -e "\n${BGREEN}Configuración de base de datos, exitosa..${NC}"
else
    echo -e "\n${BRED}Hubo un error al ejecutar el comando MySQL. Código de salida: ${BYELLOW}$?${NC}"
fi

#Descarga del repositorio

echo -e "\n${BYELLOW}Validando existencia del repositorio...${NC}"

if [ -d ${REPO} ]; then
    echo -e "\n${BBLUE}La carpeta $REPO existe, será eliminada...${NC}"
    rm -rf $REPO
fi

echo -e "\n${BYELLOW}Descargando el repositorio...${NC}"

git clone https://github.com/roxsross/$REPO.git -b $BRANCH
cp -r $REPO/app-295devops-travel/* /var/www/html
sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
mv /var/www/html/index.html /var/www/html/index.html.bkp

#Preparando la base de datos...

echo -e "\n${BBLUE}Importando tablas a la BD...${NC}"

TABLAS="mysql < bootcamp-devops-2023/app-295devops-travel/database/devopstravel.sql"

if eval $TABLAS; then
    echo -e "\n${BGREEN}La importación de tablas fue exitosa...${NC}"
else
    echo -e "\n${BRED}La importación falló. Código de salida ${BYELLOW}$?${NC}"
fi

#Ingreso de clave archivo config.php

echo -e "\n${LBLUE}Configuración de archivo de conexión entre la web y la BD..${NC}"

archivoConfig="/var/www/html/config.php"

sed -i "s/\(\$dbPassword *= *\)\(.*\)\(;.*\)/\1\"${PASSDB}\"\3/" "${archivoConfig}"

echo -e "\n${BGREEN}Configuración de archivo exitosa...!${NC}"

#Reiniciando el servicio apache2

systemctl reload apache2

echo -e "\n${BGREEN}Implementación de web exitosa!!${NC}"

#==============================================================================

# Notificacion a DISCORD

cd "$REPO"

# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="localhost"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio


# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"