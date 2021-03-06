#!/bin/sh

if [[ $7 = "true" ]]; then
    #HOST_IP=host.docker.internal
    HOST_IP=`/sbin/ip route | awk '/default/ { print $3 }'`
    sed -i "s#__ip#$HOST_IP#g" /usr/local/etc/php/conf.d/xdebug.ini;
fi

# install composer
echo 'Composer Install';
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer;
chmod +x /usr/local/bin/composer;

# install magerun2
echo 'Magerun2 Install';
curl -L https://files.magerun.net/n98-magerun2.phar > /usr/local/bin/n98-magerun2.phar \
&& chmod +x /usr/local/bin/n98-magerun2.phar

# composer downloader package to increase download speeds
su -c "composer global require hirak/prestissimo" -s /bin/sh $2

# go to magento root folder
cd $3;

if [[ $6 = "true" ]]; then
    su -c "composer update" -s /bin/sh $2
fi

# download magento 2
if [[ $1 = "true" ]]; then
	echo 'Downloading Magento 2';
    su -c "
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$4 .;
    mkdir -p var/composer_home;
    cp ../.composer/auth.json ./var/composer_home/auth.json;
    composer require --dev msp/devtools mage2tv/magento-cache-clean;
    " -s /bin/sh $2

    # set owner and user permissions on magento folders
    echo 'Set permissions';
    su -c "find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
        find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
        chmod u+x bin/magento;" -s /bin/sh $2

 <<'END'
	su -c "bin/magento setup:install \
	    --db-host=mysql \
	    --db-name=$8 \
	    --db-user=$9 \
	    --db-password=$10 \
	    --backend-frontname=admin \
	    --base-url=https://mage2.doc/ \
	    --language=de_DE \
	    --timezone=Europe/Berlin \
	    --currency=EUR \
	    --admin-lastname=Admin \
	    --admin-firstname=Admin \
	    --admin-email=admin@example.com \
	    --admin-user=admin \
	    --admin-password=admin123 \
	    --cleanup-database \
	    --use-rewrites=1 \
	    --use-sample-data" -s /bin/sh $2
END
fi

# Magento Sample Data
if [[ $5 = "true" ]]; then
	echo 'Downloading Sample Data';
    su -c "bin/magento sampledata:deploy;" -s /bin/sh $2
fi