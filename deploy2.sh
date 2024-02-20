#!/bin/bash

# 1. Definir variables
repo="bootcamp-devops-2023"
USERID=$(id -u)

echo "===================== Inicio validación usuario root ==========================="
# 2. Validar que el usuario es ROOT
if [ "${USERID}" -ne 0 ]; then
    echo "Correr script como usuario ROOT..."
    exit 1
fi
echo " ===================== Fin validación de usuario ==============================="
# 3. Actualizar el sistema operativo
echo "Verificando las últimas actualizaciones del sistema..."
apt-get update
if apt-get upgrade -y; then
    echo "El sistema está actualizado..."
else
    echo "Actualizando el sistema..."
fi

echo "====================== Fin actualización de sistema operativo ========================"

echo "======================= Instalando GIT =================================="
# 4. Verificar e instalar git
if dpkg -s "git" >/dev/null 2>&1; then
    echo "Git está instalado..."
else
    echo "Instalando git..."
    apt-get install -y git
fi



# 5. Verificar e instalar mariadb-server
if dpkg -s "mariadb-server" >/dev/null 2>&1; then
    echo "MariaDB está instalado..."
else
    echo "Instalando MariaDB..."
    apt-get install -y mariadb-server
    systemctl start mariadb
    systemctl enable mariadb
fi

# 6. Configurar la base de datos
mysql -e "
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"




# 7. Verificar e instalar apache2
if dpkg -s "apache2" >/dev/null 2>&1; then
    echo "Apache2 está instalado..."
else
    echo "Instalando Apache2..."
    apt-get install -y apache2
fi

# 8. Verificar e instalar php y módulos
if dpkg -s "php" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" >/dev/null 2>&1; then
    echo "PHP está instalado..."
else
    echo "Instalando PHP y módulos..."
    apt-get install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
fi

# 9. Iniciar y habilitar apache2
systemctl start apache2
systemctl enable apache2

# 10. Verificar la instalación de php
php -v

# 11. Configurar apache para soportar php
echo "<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-enabled/dir.conf

# 12. Recargar apache2
systemctl reload apache2

# 13. Crear archivo de configuración de la base de datos
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

# 14. Clonar repositorio de git, renombrar archivo y copiar directorio
if [ -d "$repo" ]; then
    echo "La carpeta $repo existe..."
    git -C $repo pull
else
    git clone https://github.com/roxsross/$repo.git
    mv /var/www/html/index.html /var/www/html/index.html.bkp
    cp -r $repo/* /var/www/html/
fi

# 15. Recargar apache2
systemctl reload apache2

# 16. Verificar el funcionamiento de php
curl localhost/info.php

echo "Fin del Script"
