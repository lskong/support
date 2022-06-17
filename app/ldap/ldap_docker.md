# ldap docker

利用 docker 快速搭建一套企业用户目录，包含 OpenLDAP、PhpLdapAdmin


- docker-compose

```yaml
version: '2'
services:
  ldap-openldap:
    container_name: ldap-openldap
    image: dinkel/openldap    # 如果拉取速度很慢，可以换成 registry.cn-hangzhou.aliyuncs.com/bxwill/openldap
    restart: always
    ports:
      - "389:389"
    environment:
      - SLAPD_PASSWORD=opendevops    # 自定义 admin 的密码
      - SLAPD_DOMAIN=qualitysphere.github.io    # 自定义 LDAP 的域名，admin 账号即 cn=admin,dc=qualitysphere,dc=github,dc=io
    volumes:
      - ./ldap/db:/var/lib/ldap
      - ./ldap/config:/etc/ldap
  ldap-phpldapadmin:
    container_name: ldap-phpldapadmin
    image: dinkel/phpldapadmin    # 如果拉取速度很慢，可以换成 registry.cn-hangzhou.aliyuncs.com/bxwill/phpldapadmin
    restart: always
    ports:
      - "8080:80"
    environment:
      - LDAP_SERVER_HOST=ldap-openldap    # 使用 compose 启动容器，可以直接使用服务名
```

- 启动容器

```shell
docker-compose -f docker-compose.yaml up -d
```