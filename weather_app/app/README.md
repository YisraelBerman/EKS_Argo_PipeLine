
# Web app

The project is an app that the user can use to get the forcast for a week ahead for ant location in the world.




## Features

- Simple site
- Easy to use
- Gives response if location not known
- Presents the forcast for day and night and humidity levels


## requirements

- Python
- Flask
- Jinja
- Gunicorn
- Nginx
## Documentation

1. Run Gunicorn as service
2. Run Nginx
    
    Site is up!

## Installation

copy .py and .HTML files to directory
    
    /home/{user}/myproject/weather
Create Gunicorn service

/etc/systemd/system/weather.service
```
    [Unit]
    Description=Gunicorn instance to serve weather
    After=network.target

    [Service]
    User=yisraelb
    Group=www-data
    WorkingDirectory=/home/{user}/myproject/weather
    Environment="PATH=/home/{user}/myproject/weather"
    ExecStart=/usr/bin/gunicorn --workers 30 --bind 127.0.0.1:5000 -m 007 wsgi:app
    
    [Install]
    WantdBy=multy-user.target

```
sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
    
Configure Nginx

/etc/nginx/sites-available/weather
```
  server {
    listen 80;
    listen 9090;
     
    server_name 10.1.0.40;
    deny 10.1.0.53;
    limit_conn conn_limit_per_ip 5;

  
    location / {
	limit_req zone=limitreqsbyaddr burst=5 nodelay;
        include proxy_params;
        proxy_pass http://127.0.0.1:5000;
      

    }
}

```
/etc/nginx/nginx.conf
    
    add to HTML section
``` 
    limit_req_zone $binary_remote_addr zone=limitreqsbyaddr:20m rate=1r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

```
    
