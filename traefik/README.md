# Certbot wildcard certificate generation

Those steps are taken from https://phoenixnap.com/kb/letsencrypt-docker. Replace `${PUBLIC_DOMAIN}` with the domain name you have to get the cert for, with a wildcard on the left.

## 1. Write your .env file
Write something like `PUBLIC_DOMAIN=my.domain.name` in a `.env` file WITHOUT wildcard.

## 2. Dry run certbot to see if everything is ok

Run this command then follow the instructions. Retry it until the value for `_acme-channel.${PUBLIC_DOMAIN}` doesn't contain special characters like "_" or "|" so you can do this in every DNS provider.
Then follow the instructions.

```bash
docker compose -f certbot.docker-compose.yml run --rm certbot certonly --manual --preferred-challenges dns --dry-run -d "*.peppolab.giuseppebosa.eu"
```

To check if the DNS txt password is available:

```shell
dig -t txt _acme-challenge.peppolab.giuseppebosa.eu
```

## 3. Run certbot if everything was ok
Run this command then follow the instructions. Retry it until the value for `_acme-channel.${PUBLIC_DOMAIN}` doesn't contain special characters like "_" or "|" so you can do this in every DNS provider.
Then follow the instructions.

```bash
docker compose -f certbot.docker-compose.yml run --rm certbot certonly --manual --preferred-challenges dns -d *.peppolab.giuseppebosa.eu
```

## 4. Down everything
```bash
docker compose -f certbot.docker-compose.yml down
docker compose down
```

## 5. Up everything

```bash
docker compose up
```
