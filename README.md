-  install software: `sudo apt install certbot python3-certbot-nginx`
-  obtain and install an SSL certificate for the domain git2nixsha.dev using Certbot and NGINX: `sudo certbot --nginx -d git2nixsha.dev`
-  create following file: `/etc/nginx/sites-available/git2nixsha.de

```
# HTTP server block to redirect HTTP to HTTPS
server {
    listen 80;
    server_name git2nixsha.dev;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl;
    server_name git2nixsha.dev;

    ssl_certificate /etc/letsencrypt/live/git2nixsha.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/git2nixsha.dev/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location /hash {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

    }

}
```

- firewall rule: `sudo ufw allow 'Nginx Full'`
- reload nginx: `sudo systemctl reload nginx`
