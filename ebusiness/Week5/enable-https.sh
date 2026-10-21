#!/bin/bash
# Προαιρετικό HTTPS για το PrestaShop της εργασίας (Caddy + Let's Encrypt). Τρέξτε το από Run command ΑΦΟΥ ανοίξετε τη θύρα 443.
# ---- Προαιρετικό: HTTPS με Caddy (Let's Encrypt). ΑΛΛΑΞΕ το DOMAIN.
DOMAIN="uom-eshop-demo.spaincentral.cloudapp.azure.com"
cd /opt/eshop
# 1) το PrestaShop να ακούει μόνο τοπικά στη θύρα 8080
sed -i 's/      - "80:80"/      - "127.0.0.1:8080:80"/' compose.yaml
# 2) Caddy: παίρνει μόνο του πιστοποιητικό και προωθεί στο PrestaShop
grep -q 'image: caddy' compose.yaml || cat >> compose.yaml <<EOC
  caddy:
    image: caddy:2
    restart: always
    network_mode: host
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddydata:/data
EOC
grep -q '^  caddydata:' compose.yaml || echo '  caddydata:' >> compose.yaml
cat > Caddyfile <<EOC
$DOMAIN {
    reverse_proxy 127.0.0.1:8080 {
        header_up X-Forwarded-Proto https
    }
}
EOC
# 3) το PrestaShop να ξέρει το νέο όνομα και ότι έχει SSL
docker compose exec -T db mariadb -uroot -pprestashop prestashop -e "update ps_shop_url set domain='$DOMAIN', domain_ssl='$DOMAIN'; update ps_configuration set value='$DOMAIN' where name in ('PS_SHOP_DOMAIN','PS_SHOP_DOMAIN_SSL'); update ps_configuration set value='1' where name in ('PS_SSL_ENABLED','PS_SSL_ENABLED_EVERYWHERE');"
docker compose up -d
echo "Σε 1-2 λεπτά: https://$DOMAIN"
