# Cheatsheet nginx - Commands and common blocks

## Commands

| Topic   | Command   | Command details                          | Description                                              |
|---------|-----------|------------------------------------------|----------------------------------------------------------|
| check   | nginx     | `sudo nginx -t`                          | Test the configuration before applying it                |
| apply   | systemctl | `sudo systemctl reload nginx`            | Reload without dropping connections                      |
| apply   | systemctl | `sudo systemctl restart nginx`           | Full restart                                             |
| logs    | tail      | `sudo tail -f /var/log/nginx/error.log`  | Follow the errors                                        |
| logs    | tail      | `sudo tail -f /var/log/nginx/access.log` | Follow the requests                                      |
| config  | nginx     | `sudo nginx -T`                          | Print the whole configuration as nginx reads it          |

## Reverse proxy to an app

```nginx
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## HTTPS with Let's Encrypt and redirection

| Topic | Command | Command details                                         | Description                                   |
|-------|---------|---------------------------------------------------------|-----------------------------------------------|
| cert  | certbot | `sudo certbot --nginx -d app.example.com`               | Get a certificate and edit the server block   |
| cert  | certbot | `sudo certbot renew --dry-run`                          | Check that the renewal works                  |

```nginx
server {
    listen 80;
    server_name app.example.com;
    return 301 https://$host$request_uri;
}
```

## Useful bits

```nginx
client_max_body_size 50m;            # accept bigger uploads
location /static/ { expires 30d; }   # cache static files
location ~ /\. { deny all; }         # hide dot files
gzip on;                             # compress text responses
```

With Nginx Proxy Manager, the same settings are in the web interface (Proxy Hosts, SSL, Advanced).
