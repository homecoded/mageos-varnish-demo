# Demonstration of using Varnish with Docker

This is a simple docker setup for hosting and installing Magento2.
The setup is based on https://gitlab.com/lumnn/magento2-docker-compose.

Please note: 

- This setup is not using Adobe's Magento but the free variant MageOS.
- I also changed the base directory of Magento so there are no 2 git repos in the very same folder. 

# Getting started

Clone the repo.
Run the following commands

    docker-compose up
    ./setup-magento.sh

After a few minutes, you will have a working Magento installation running on http://localhost/

## E-mails

All emails from PHP containers can be seen in Mailhog at http://localhost:8025
