
## radosgw
```conf
upstream s3 {
server 10.0.0.23:7480  fail_timeout=10s max_fails=1;
server 10.0.0.24:7480  fail_timeout=10s max_fails=1;
server 10.0.0.25:7480  fail_timeout=10s max_fails=1;
}
server {
listen 8000;
client_max_body_size 0;
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Expect $http_expect;
location / {
proxy_pass     http://s3;
proxy_buffering off;
proxy_redirect off;
proxy_connect_timeout 45s;
proxy_send_timeout 45s;
proxy_read_timeout 45s;
}
}
```



## qcos

```conf
upstream qcos {
server 10.0.0.23:8180  fail_timeout=10s max_fails=1;
server 10.0.0.24:8180  fail_timeout=10s max_fails=1;
server 10.0.0.25:8180  fail_timeout=10s max_fails=1;
}
server {
listen 8087;
client_max_body_size 0;
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Expect $http_expect;
location / {
proxy_pass     http://qcos;
proxy_buffering off;
proxy_redirect off;
proxy_connect_timeout 45s;
proxy_send_timeout 45s;
proxy_read_timeout 45s;
}
}
```


# ssl
upstream stats {
server 172.16.103.21:3000  fail_timeout=60s max_fails=1;
server 172.16.103.22:3000  fail_timeout=60s max_fails=1;
server 172.16.103.23:3000  fail_timeout=60s max_fails=1;
}
server {
listen 443 ssl;
server_name 172.16.103.21;
ssl_certificate     /opt/petasan/config/certificates/server.crt;
ssl_certificate_key /opt/petasan/config/certificates/server.key;
location /grafana/ {
proxy_pass     http://stats/;
proxy_connect_timeout 5s;
proxy_send_timeout 5s;
proxy_read_timeout 5s;
}
location / {
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_redirect http://$http_host/ https://$http_host/;
proxy_pass  http://127.0.0.1:5002;
}
}
server {
listen 80 default_server;
listen 5000;
server_name 172.16.103.21;
root /var/www/html/;
index download_certificate.html;
}