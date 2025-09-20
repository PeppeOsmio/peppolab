FROM garethgeorge/backrest:v1.9.1

RUN apk update --no-cache && apk add btrfs-progs docker-cli-compose

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/backrest", "--bind-address", ":9898"]