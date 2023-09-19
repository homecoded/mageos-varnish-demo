# Demonstration of using Varnish with Docker

This is a simple docker setup for hosting and installing Magento2.
The setup is based on https://gitlab.com/lumnn/magento2-docker-compose.
I comes complete with sample data.

*Please note:* 

- This setup is not using Adobe's Magento but the free variant MageOS.
- I also changed the base directory of Magento so there are no 2 git repos in the very same folder. 
- The setup uses MageOS' sample data.
- The web server runs on ports 8080 and 8443 so port 80 and 443 is open for varnish.

# Getting started

Clone the repo.
Run the following commands

    docker-compose up
    ./setup-magento.sh

After a few minutes, you will have a working Magento installation running on http://localhost/

# Useful Info About Magento 2

## Admin Interface

Here is the admin URL and the corresponding access credentials.

    http://localhost:8080/admin
    User: admin
    Pasword: easy123

## Accessing The Database

Use this command outside the docker container to get a mysql shell.

    docker-compose exec db mysql -u magento -pmagento2 magento

## Accessing The PHP instance shell

If you need to access the shell on the web server:

    ## root access
    docker exec -u root -it varnished_magento_php_1 /bin/bash

    ## app user access
    docker exec -it varnished_magento_php_1 /bin/bash

## E-mails

All emails from PHP containers can be seen in Mailhog at http://localhost:8025

# Installing varnish

First, we install varnish on the php instance:

    # ssh into instance
    docker exec -u root -it varnished_magento_php_1 /bin/bash

    # install varnish
    apt-get update
    apt-get install varnish

Go into the backend and generate a varnish-config.

    # start varnish
    /usr/sbin/varnishd \
	  -a :80 \
	  -a localhost:8080,PROXY \
	  -p feature=+http2 \
	  -f /etc/varnish/default.vcl \
	  -s malloc,2g
    
