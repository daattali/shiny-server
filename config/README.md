These are some of the configuration files that are used on the server

- **[index.html](./index.html)** `/usr/share/nginx/html/index.html` nginx index file
- **[default](./default)** `/etc/nginx/sites-enabled/default` nginx config file
- **[monitorix.conf](./monitorix.conf)** `/etc/monitorix/monitorix.conf` monitorix config file
- **[shiny-server.conf](./shiny-server.conf)** `/etc/shiny-server/shiny-server.conf` shiny server config file


Instructions for setting up SSL: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04

Setting up firewall:

```
sudo ufw allow ssh
sudo ufw allow https
sudo ufw allow ftp
sudo ufw enable
```
