#!/bin/bash
cd "$(dirname "$0")"
./dockerbin/create-self-signed-ssl

docker-compose exec --user root php chown -R app:app .
docker-compose exec php mkdir "magento"
docker-compose exec -w /var/www/html php git init
docker-compose exec -w /var/www/html php git config pull.rebase true
docker-compose exec -w /var/www/html php git remote add origin https://github.com/mage-os/mageos-magento2
docker-compose exec -w /var/www/html php git pull origin 2.4-develop --force
docker-compose exec -w /var/www/html php composer install
docker-compose exec -w /var/www/html php bin/magento setup:install \
    --db-host=db \
    --db-user=magento \
    --db-password=magento2 \
    --db-name=magento \
    --backend-frontname=admin \
    --timezone="Europe/Berlin" \
    --currency=EUR \
    --base-url=http://localhost:8080/ \
    --base-url-secure=https://localhost:8443/ \
    --use-rewrites=1 \
    --use-secure=1 \
    --use-secure-admin=1 \
    --admin-user=admin \
    --admin-password=easy123 \
    --admin-firstname=Admin \
    --admin-lastname=Magento \
    --admin-email=magento@homecoded.com \
    --search-engine=elasticsearch7 \
    --elasticsearch-host=elasticsearch \
    --elasticsearch-port=9200 \
    --elasticsearch-index-prefix=magento2 \
    --elasticsearch-timeout=15
docker-compose exec -w /var/www/html php mkdir sampledata
docker-compose exec -w /var/www/html/sampledata php git clone https://github.com/mage-os/mageos-magento2-sample-data.git .
docker-compose exec -w /var/www/html/sampledata php php -f dev/tools/build-sample-data.php -- --ce-source="/var/www/html/"



docker-compose exec -w /var/www/html php bin/magento deploy:mode:set developer
docker-compose exec -w /var/www/html php bin/magento setup:upgrade
docker-compose exec -w /var/www/html php rm -rf generated/code/* generated/metadata/*
docker-compose exec -w /var/www/html php bin/magento sampledata:deploy
