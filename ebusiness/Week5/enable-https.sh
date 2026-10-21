#!/bin/bash
# Προαιρετικό HTTPS για το PrestaShop της εργασίας (Caddy + Let's Encrypt).
# Τρέξτε το από Run command ΑΦΟΥ (α) έχετε όνομα που δείχνει στη μηχανή, (β) ανοίξετε τη θύρα 443.
DOMAIN="uom-eshop-demo.spaincentral.cloudapp.azure.com"   # ΑΛΛΑΞΤΕ ΤΟ: το δικό σας όνομα
# -------------------------------------------------------------------------------------------
set -e
cd /opt/eshop
# 1) Το PrestaShop ακούει μόνο τοπικά, στη θύρα 8080· μπροστά του μπαίνει ο Caddy
sed -i 's/      - "80:80"/      - "127.0.0.1:8080:80"/' compose.yaml
# 2) Προσθήκη του Caddy στα services (πριν από το "volumes:") και του volume του
if ! grep -q 'image: caddy' compose.yaml; then
python3 - <<'PY'
s=open('compose.yaml').read()
caddy='''  caddy:
    image: caddy:2
    restart: always
    network_mode: host
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddydata:/data
'''
i=s.index('\nvolumes:\n')
s=s[:i+1]+caddy+s[i+1:]
if not s.rstrip().endswith('caddydata:'): s=s.rstrip('\n')+'\n  caddydata:\n'
open('compose.yaml','w').write(s)
PY
fi
cat > Caddyfile <<EOC
$DOMAIN {
    reverse_proxy 127.0.0.1:8080 {
        header_up X-Forwarded-Proto https
    }
}
EOC
# 3) Το PrestaShop μαθαίνει το νέο όνομα και ότι έχει SSL
docker compose exec -T db mariadb -uroot -pprestashop prestashop -e "update ps_shop_url set domain='$DOMAIN', domain_ssl='$DOMAIN'; update ps_configuration set value='$DOMAIN' where name in ('PS_SHOP_DOMAIN','PS_SHOP_DOMAIN_SSL'); update ps_configuration set value='1' where name in ('PS_SSL_ENABLED','PS_SSL_ENABLED_EVERYWHERE');"
docker compose up -d
echo "Σε 1-2 λεπτά: https://$DOMAIN"
