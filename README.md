This repository contains the code and instructions to build and run an R plumber api on digital ocean with a custom domain and with ssh enabled.

- Clone the repo
- Install Nix (using the Determinate Nix installer for example: https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#install-nix
- Build the environment: `nix-build default.nix` (you can omit the `default.nix`)
- You can now run the api using the included bash script: `./run_api.sh` (you likely will need to adapt the paths therein to point to the R script)
- I use `run-one` to avoid running multiple instances of the api: `sudo apt-get install run-one` then `nohup run-one nix_hash_api/run_api.sh &`
- To serve the api with a custom domain and with ssh enabled, you'll need `nginxg` and get a certificate
- Install software: `sudo apt install certbot python3-certbot-nginx`
- Obtain and install an SSL certificate for the domain git2nixsha.dev using Certbot and NGINX: `sudo certbot --nginx -d git2nixsha.dev`
- Create following file: `/etc/nginx/sites-available/git2nixsha.de

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

- Add the following firewall rule: `sudo ufw allow 'Nginx Full'`
- Reload nginx: `sudo systemctl reload nginx`

If you want to use docker instead I highly recommend you follow: https://github.com/andrewheiss/docker-plumber-nginx-letsencrypt
