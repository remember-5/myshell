touch .komari-auto-discovery.json && docker run -d --name komari-agent \
  --restart=always \
  -v .komari-auto-discovery.json:/app/auto-discovery.json \
  ghcr.io/komari-monitor/komari-agent:1.2.13 \
  -e http://192.168.0.1:25774 \
  --auto-discovery xxxxxx \
  --custom-ipv4 192.168.0.1