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

    http://localhost:8080/admin/
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
    apt-get -y install varnish
    
Next step, we go into the backend

    # go into the backend
    http://localhost:8080/admin/
        User: admin
        Pasword: easy123

Navigate to *Stores -> Configuration -> Advanced -> System -> Full Page Cache*. Switch "Caching Application" to 
"Varnish Cache". Click "Save Config".

Or do it on the command line:

    bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2

    # generate varnish config
    bin/magento varnish:vcl:generate --export-version=6 > /etc/varnish/default.vcl
    sed -i 's/localhost/nginx/g' /etc/varnish/default.vcl

    # enable developer mode
    bin/magento deploy:mode:set developer

    # switch base url to varnish
    bin/magento config:set web/unsecure/base_url http://localhost/
    bin/magento config:set web/secure/base_url https://localhost/
    bin/magento cache:flush
    
    # make sure the rights are correct (we ran bin/magento with root!)
    chown -R app:app /var/www/html

Start varnish

    # start varnish
    /usr/sbin/varnishd \
      -a :80 \
	  -T localhost:8080 \
	  -p feature=+http2 \
	  -f /etc/varnish/default.vcl \
	  -s malloc,2g
    
# Debugging varnish

For the next step you need two open shells, one root and one app shell
    
    # open root shell
    docker exec -u root -it varnished_magento_php_1 /bin/bash
    # start varnish log
    varnishlog

    # open app shell
    docker exec -it varnished_magento_php_1 /bin/bash
    # clear cache
    bin/magento cache:flush

Check the varnish log of the root shell. It should show a PURGE request but with the error
"Method not allowed". This is because the requesting host does not match any of the allowed hosts.

    # go to the root shell and stop varnishlog (CTRL-C)
    # install a text editor (nano, vim, emacs, ...)
    apt-get -y install nano

    # install some debugging tools
    apt-get -y install procps net-tools

    # edit the varnish config
    nano /etc/varnish/default.vcl
    
    # find the Access Control List (acl) for purge and change the entry from "nginx" to "localhost"
    acl purge {
        "localhost";
    }

Now, save and exit the text editor. Now, we need to restart varnish:

    ps aux | grep varnish

This will give you several entries. You want the one that has "varnish" in the first column. Check the PID in the 
second column.

    # kill the process by PID
    kill <PID>
    
Now, restart varnish

    /usr/sbin/varnishd \
      -a :80 \
	  -T localhost:8080 \
	  -p feature=+http2 \
	  -f /etc/varnish/default.vcl \
	  -s malloc,2g

Open another root-shell and start varnishlog. Then, call "cache:flush" from the app shell and see, that the purge
request passes sucessfully.

Visit http://localhost/ in your browser and see the website served by varnish.

# In case of emergency

If you need some debugging tools in the container

    apt-get -y install procps nano net-tools 