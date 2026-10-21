#!/bin/bash
# =====================================================================
#  Εγκατάσταση PrestaShop 9 σε Ubuntu VM με Docker
#  Ηλεκτρονικό Επιχειρείν · Πανεπιστήμιο Μακεδονίας · Εβδομάδα 5
#
#  Τρέξτε το από το Azure portal: VM > Operations > Run command > RunShellScript
#  (ή με sudo bash install-prestashop.sh σε οποιαδήποτε Ubuntu VM, π.χ. Google Cloud)
#
#  ΑΛΛΑΞΤΕ ΤΙΣ ΔΥΟ ΓΡΑΜΜΕΣ ΑΠΟ ΚΑΤΩ ΠΡΙΝ ΤΟ ΤΡΕΞΕΤΕ.
# =====================================================================
ADMIN_MAIL="onoma@uom.edu.gr"        # το email με το οποίο θα μπαίνετε στο back office
ADMIN_PASSWD="Allaxte-Me-2026"       # τουλάχιστον 8 χαρακτήρες, χωρίς κενά και χωρίς ' ή "
# ---------------------------------------------------------------------
set -e
export DEBIAN_FRONTEND=noninteractive

echo ">>> 1/4 Εγκατάσταση Docker"
apt-get update -y
apt-get install -y docker.io docker-compose-v2 curl
systemctl enable --now docker

echo ">>> 2/4 Εύρεση δημόσιας IP"
IP=$(curl -s -m 5 -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01&format=text" || true)
if [ -z "$IP" ]; then IP=$(curl -s -m 5 -H "Metadata-Flavor: Google" "http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" || true); fi
if [ -z "$IP" ]; then IP=$(curl -s -m 5 https://ifconfig.me || true); fi
echo "    IP: $IP"

echo ">>> 3/4 Αρχείο compose"
mkdir -p /opt/eshop && cd /opt/eshop
cat > compose.yaml <<EOF
services:
  db:
    image: mariadb:11.4
    restart: always
    environment:
      MARIADB_ROOT_PASSWORD: prestashop
      MARIADB_DATABASE: prestashop
    volumes:
      - dbdata:/var/lib/mysql
  shop:
    image: prestashop/prestashop:9.2-apache
    restart: always
    depends_on:
      - db
    ports:
      - "80:80"
    environment:
      DB_SERVER: db
      DB_USER: root
      DB_PASSWD: prestashop
      DB_NAME: prestashop
      PS_INSTALL_AUTO: 1
      PS_DOMAIN: ${IP:-localhost}
      PS_COUNTRY: GR
      PS_LANGUAGE: en
      ADMIN_MAIL: $ADMIN_MAIL
      ADMIN_PASSWD: $ADMIN_PASSWD
    volumes:
      - psdata:/var/www/html
volumes:
  dbdata:
  psdata:
EOF

echo ">>> 4/4 Εκκίνηση (το κατέβασμα και η εγκατάσταση παίρνουν 5-10 λεπτά)"
docker compose up -d

echo
echo "=================================================================="
echo "  Κατάστημα (front office):  http://$IP"
echo "  Διαχείριση (back office):  http://$IP/admin-dev"
echo "  Email: $ADMIN_MAIL"
echo "  Περιμένετε 5-10 λεπτά πριν ανοίξετε τη διεύθυνση."
echo "=================================================================="
