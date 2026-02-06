#!/bin/bash

# Warna untuk output
GREEN='\033[032m'
CYAN='\033[036m'
YELLOW='\033[033m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}   Pterodactyl Website Domain Setup Tool      ${NC}"
echo -e "${CYAN}==============================================${NC}"
echo ""
echo "Pilih opsi:"
echo "1. Tutorial SetUp Cloudflare"
echo "2. Mulai Settings Domain (Nginx + SSL)"
echo "3. Keluar"
echo ""
read -p "Masukkan pilihan (1-3): " OPTION

case $OPTION in
    1)
        clear
        echo -e "${YELLOW}=== Tutorial SetUp Cloudflare ===${NC}"
        echo "1. Login ke dashboard Cloudflare."
        echo "2. Pilih domain Anda dan masuk ke menu 'DNS'."
        echo "3. Klik 'Add Record'."
        echo "4. Type: A | Name: @ atau subdomain | Content: (pakai ip vps)"
        echo "5. Proxy Status: Pastikan 'Not Proxied' (Awan Abu Abu) MATI."
        echo "6. Masuk ke menu 'SSL/TLS' -> Overview, ubah mode ke 'Full'."
        echo ""
        echo "Setelah selesai, silakan jalankan script lagi dan pilih nomor 2."
        ;;

        2)
        # Input Data
        read -p "Masukkan Domain/Subdomain (misal: web.anda.com): " DOMAIN
        read -p "Masukkan Port Server Pterodactyl (misal: 4000): " PORT

        echo -e "${YELLOW}Memulai instalasi Nginx...${NC}"
        sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx

        # Buat file konfigurasi Nginx
        CONF_FILE="/etc/nginx/sites-available/$DOMAIN"
        
        echo -e "${YELLOW}Membuat konfigurasi Nginx...${NC}"
        # Perhatikan tanda 'EOF' (pakai tanda kutip) agar variabel $ tidak diproses Bash
        sudo tee $CONF_FILE > /dev/null << 'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location / {
        proxy_pass http://localhost:PORT_PLACEHOLDER;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

        # Ganti placeholder dengan input user
        sudo sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" $CONF_FILE
        sudo sed -i "s/PORT_PLACEHOLDER/$PORT/g" $CONF_FILE

        # Link file ke sites-enabled
        sudo ln -sf "$CONF_FILE" "/etc/nginx/sites-enabled/"
        
        # Hapus default config jika ada agar tidak bentrok
        sudo rm -f /etc/nginx/sites-enabled/default

        # Test Nginx
        sudo nginx -t
        if [ $? -eq 0 ]; then
            sudo systemctl restart nginx
            echo -e "${GREEN}Nginx berhasil dikonfigurasi!${NC}"
            
            read -p "Apakah ingin menginstal SSL (HTTPS) sekarang? (y/n): " INSTALL_SSL
            if [ "$INSTALL_SSL" = "y" ]; then
                sudo certbot --nginx -d $DOMAIN
                echo -e "${GREEN}Proses selesai! Website Anda kini bisa diakses di https://$DOMAIN${NC}"
            else
                echo -e "${YELLOW}Selesai tanpa SSL. Website diakses di http://$DOMAIN${NC}"
            fi
        else
            echo -e "${YELLOW}Terjadi kesalahan pada konfigurasi Nginx. Mohon cek kembali.${NC}"
        fi
        ;;

    3)
        exit 0
        ;;
    *)
        echo "Pilihan tidak valid."
        ;;
esac
