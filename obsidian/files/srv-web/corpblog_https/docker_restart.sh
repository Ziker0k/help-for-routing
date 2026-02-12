#!/bin/bash
docker-compose down
docker rmi -f $(docker images -a -q)
docker load -i blog.tar
docker load -i mariadb.tar

