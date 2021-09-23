mkdir -p data config plugins
chmod 775 -R $(pwd)
cp elasticsearch.yml config
docker-compost up -d
