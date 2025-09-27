# Registry

## Create password

```shell
docker run --rm --entrypoint htpasswd httpd:2 -Bbn ${USERNAME} ${PASSWORD} > /docker_data/registry/configs/htpasswd
```
