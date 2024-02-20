#!/bin/bash

# Variables
REPO="bootcamp-devops-2023"
BRANCH="clase2-linux-bash"
USERID=$(id -u)
DISCORD="https://discord.com/api/webhooks/1202369004023590912/b7ra6RnXn6tdldm60P3hZHpBy6bf-U2m6dG6gOE13Ar96Ngx6rfd4uQmHgiXkVxFzWLt"


# Colores
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BMAGENTA='\033[1;35m'
BCYAN='\033[1;36m'
BWHITE='\033[1;37m'
NC='\033[0m'

# Validacion de usuario ROOT y variables de DB

if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${BRED}Correr con usuario ROOT.${NC}"
    exit
elif [ -z "${USERDB}" ]; then
    echo -e "\n${BRED}La variable 'USERDB' no esta definida.${NC}"
    exit
elif [ -z "${PASSDB}" ]; then
    echo -e "\n${BRED}La variable 'PASSDB' no esta definida.${NC}"
    exit
fi

# Validacion e instalacion de GIT, Apache2, PHP y MariaDB

echo -e "\n${BBLUE}Validando e instalando GIT, Apache2, PHP y MariaDB...${NC}"
sleep 1

    #Update

echo -e "\n${BYELLOW}Actualizando servidor...${NC}"
apt-get update
echo -e "\n${BGREEN}Servidor actualizado.${NC}"
    
    # GIT

echo -e "\n${BYELLOW}Validando GIT...${NC}"

if dpkg -s git > /dev/null 2>&1; then
    echo -e "\n${BGREEN}GIT ya estaba instalado.${NC}"
else
    echo -e "\n${BYELLOW}instalando GIT ...${NC}"
    apt install -y git
    echo -e "\n${BGREEN}GIT instalado.${NC}"
fi

    # Apache2 y PHP

echo -e "\n${BYELLOW}Validando Apache2, PHP y componentes...${NC}"

if dpkg -s apache2 > /dev/null 2>&1; then
    echo -e "\n${BGREEN}Apache2 ya estaba instalado.${NC}"
else
    echo -e "\n${BYELLOW}Instalando Apache2 ...${NC}"
    apt install -y apache2
    echo -e "\n${BGREEN}Apache2 instalado.${NC}"
fi

if dpkg -s php > /dev/null 2>&1; then
    echo -e "\n${BGREEN}PHP ya estaba instalado.${NC}"
else
    echo -e "\n${BYELLOW}Instalando PHP...${NC}"
    apt install -y php
    echo -e "\n${BGREEN} PHP Instalado.${NC}"
fi

if dpkg -s libapache2-mod-php > /dev/null 2>&1; then
    echo -e "\n${BGREEN}Componente PHP ya estaba instalado (libapache2).${NC}"
else
    echo -e "\n${BYELLOW}Instalando componente PHP (libapache2)...${NC}"
    apt install -y libapache2-mod-php
    echo -e "\n${BGREEN} Componente instalado (libapache2).${NC}"
fi

if dpkg -s php-mysql > /dev/null 2>&1; then
    echo -e "\n${BGREEN}Componente PHP ya estaba instalado (php-mysql).${NC}"
else
    echo -e "\n${BYELLOW}Instalando componente PHP (php-mysql)...${NC}"
    apt install -y php-mysql
    echo -e "\n${BGREEN} Componente instalado (php-mysql).${NC}"
fi

    # MariaDB

echo -e "\n${BYELLOW}Validando MariaDB...${NC}"

if dpkg -s mariadb-server > /dev/null 2>&1; then
    echo -e "\n${BGREEN}MariaDB ya estaba instalado.${NC}"
else
    echo -e "\n${BYELLOW}Instalando MariaDB...${NC}"
    apt install -y mariadb-server
    echo -e "\n${BGREEN}MariaDB instalado.${NC}"
fi

# Habilitando servicios

echo -e "\n${BYELLOW}Habilitando servicios.${NC}"

systemctl start apache2
systemctl enable apache2

systemctl start mariadb
systemctl enable mariadb

echo -e "\n${BGREEN}Servicios habilitados.${NC}"

# Configuracion de la base de datos

echo -e "\n${BYELLOW}Configurando base de datos ...${NC}"


MYSQL_COMMAND="mysql -e \"CREATE DATABASE IF NOT EXISTS devopstravel; \
           CREATE USER IF NOT EXISTS '${USERDB}'@'localhost' IDENTIFIED BY '${PASSDB}'; \
           GRANT ALL PRIVILEGES ON devopstravel.* TO '${USERDB}'@'localhost'; \
           FLUSH PRIVILEGES;\""

if eval $MYSQL_COMMAND; then
    echo -e "\n${BGREEN}Configuración de Base de datos, usuario y contraseña realizada correctamente.${NC}"
else
    echo -e "\n${BRED}Hubo un error al ejecutar el comando MySQL. Código de salida: ${BYELLOW}$?${NC}"
fi

# Descarga de pagina web

echo -e "\n${BBLUE}Descargando pagina web.${NC}"

echo -e "\n${BYELLOW}Validando informacion preexistente..${NC}"

if [ -d ${REPO} ]; then
    echo -e "\n${BBLUE}La carpeta $REPO existe, sera reemplazada ...${NC}"
    rm -rf $REPO
fi

echo -e "\n${BYELLOW}instalando WEB ...${NC}"

git clone https://github.com/roxsross/$REPO.git -b $BRANCH
cp -r $REPO/app-295devops-travel/* /var/www/html
sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
mv /var/www/html/index.html /var/www/html/index.html.bkp

# Preparando base de dato

echo -e "\n${BBLUE}Preparando base de datos...${NC}"

echo -e "\n${BYELLOW}Importando tablas a la base${NC}"

TABLAS="mysql < bootcamp-devops-2023/app-295devops-travel/database/devopstravel.sql"

if eval $TABLAS; then
    echo -e "\n${BGREEN}Las tablas fueron importadas exitosamente.${NC}"
else
    echo -e "\n${BRED}Hubo un error en la importacion. Código de salida: ${BYELLOW}$?${NC}"
fi

# Reemplazo de password

echo -e "\n${BBLUE}Configuracion archivo de conexion entre Pagina y Base de datos.${NC}"

archivoConfig="/var/www/html/config.php"

sed -i "s/\(\$dbPassword *= *\)\(.*\)\(;.*\)/\1\"${PASSDB}\"\3/" "${archivoConfig}"

sed -i "s/codeuser/${USERDB}/g" ${archivoConfig}

echo -e "\n${BGREEN}Configuracion exitosa.${NC}"

# reload
systemctl reload apache2

echo -e "\n${BMAGENTA}IMPLEMENTACION LAMP EXITOSA${NC}"

# ==========================================================================

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