#!/bin/bash

cd ~/containers/services/proxy
docker compose exec proxy-nginx nginx -s reload
cd -