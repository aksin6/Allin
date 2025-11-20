"#!/bin/bash

# Color
BLUE='\033[0;34m'       
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Display welcome message
display_welcome() {
  echo -e ""
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]                                                 [+]${NC}"
  echo -e "${BLUE}[+]                AUTO INSTALLER PANEL             [+]${NC}"
  echo -e "${BLUE}[+]                     © @gudel023                  [+]${NC}"
  echo -e "${BLUE}[+]                                                 [+]${NC}"
  echo -e "${RED}[+] =============================================== [+]${NC}"
  echo -e ""
  echo -e "script ini di buat untuk mempermudah penginstalasian thema pterodactyle,"
  echo -e "dilarang keras untuk dikasih gratis."
  echo -e ""
  echo -e "𝗧𝗘𝗟𝗘𝗚𝗥𝗔𝗠 :"
  echo -e "@gudel023"
  echo -e "𝗖𝗥𝗘𝗗𝗜𝗧𝗦 :"
  echo -e "@gudel023"
  sleep 4
  clear
}

#Update and install jq
install_jq() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]             UPDATE & INSTALL JQ                 [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sudo apt update && sudo apt install -y jq
  if [ $? -eq 0 ]; then
    echo -e "                                                       "
    echo -e "${GREEN}[+] =============================================== [+]${NC}"
    echo -e "${GREEN}[+]              INSTALL JQ BERHASIL                [+]${NC}"
    echo -e "${GREEN}[+] =============================================== [+]${NC}"
  else
    echo -e "                                                       "
    echo -e "${RED}[+] =============================================== [+]${NC}"
    echo -e "${RED}[+]              INSTALL JQ GAGAL                   [+]${NC}"
    echo -e "${RED}[+] =============================================== [+]${NC}"
    exit 1
  fi
  echo -e "                                                       "
  sleep 1
  clear
}
#Check user token
check_token() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]               LICENCE GUDEL DEV            [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  echo -e "${YELLOW}MASUKAN AKSES TOKEN :${NC}"
  read -r USER_TOKEN

  if [ "$USER_TOKEN" = "gudelganteng" ]; then
    echo -e "${GREEN}AKSES BERHASIL${NC}}"
  else
    echo -e "${GREEN}Buy dulu Gih Ke @gudel023${NC}"
    echo -e "${YELLOW}TELEGRAM : @gudel023${NC}"
    echo -e "${YELLOW}HARGA TOKEN : 25K FREE UPDATE JIKA ADA TOKEN BARU${NC}"
    echo -e "${YELLOW}©gudel023${NC}"
    exit 1
  fi
  clear
}

# Uninstall theme
uninstall_theme() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]                    DELETE THEME                 [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  bash <(curl https://raw.githubusercontent.com/gitfdil1248/thema/main/repair.sh)
  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]                 DELETE THEME SUKSES             [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sleep 2
  clear
}
install_themeSteeler() {
#!/bin/bash

echo -e "                                                       "
echo -e "${BLUE}[+] =============================================== [+]${NC}"
echo -e "${BLUE}[+]                  INSTALLASI THEMA               [+]${NC}"
echo -e "${BLUE}[+] =============================================== [+]${NC}"
echo -e "                                                                   "

# Unduh file tema
wget -O /root/C2.zip https://github.com/gitfdil1248/thema/raw/main/C2.zip

# Ekstrak file tema
unzip /root/C2.zip -d /root/pterodactyl

# Salin tema ke direktori Pterodactyl
sudo cp -rfT /root/pterodactyl /var/www/pterodactyl

# Instal Node.js dan Yarn
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm i -g yarn

# Instal dependensi dan build tema
cd /var/www/pterodactyl
yarn add react-feather
php artisan migrate
yarn build:production
php artisan view:clear

# Hapus file dan direktori sementara
sudo rm /root/C2.zip
sudo rm -rf /root/pterodactyl

echo -e "                                                       "
echo -e "${GREEN}[+] =============================================== [+]${NC}"
echo -e "${GREEN}[+]                   INSTALL SUCCESS               [+]${NC}"
echo -e "${GREEN}[+] =============================================== [+]${NC}"
echo -e ""
sleep 2
clear
exit 0

}
create_node() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]                    CREATE NODE                     [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  #!/bin/bash
#!/bin/bash

# Minta input dari pengguna
read -p "Masukkan nama lokasi: " location_name
read -p "Masukkan deskripsi lokasi: " location_description
read -p "Masukkan domain: " domain
read -p "Masukkan nama node: " node_name
read -p "Masukkan RAM (dalam MB): " ram
read -p "Masukkan jumlah maksimum disk space (dalam MB): " disk_space
read -p "Masukkan Locid: " locid

# Ubah ke direktori pterodactyl
cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

# Membuat lokasi baru
php artisan p:location:make <<EOF
$location_name
$location_description
EOF

# Membuat node baru
php artisan p:node:make <<EOF
$node_name
$location_description
$locid
https
$domain
yes
no
no
$ram
$ram
$disk_space
$disk_space
100
8080
2022
/var/lib/pterodactyl/volumes
EOF

  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]        CREATE NODE & LOCATION SUKSES             [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sleep 2
  clear
  exit 0
}
install_dependencies() {
    local installed=0
    
    # Check and install jq
    if ! command -v jq &> /dev/null; then
        echo -e "\033[0;33m[!] Installing jq...\033[0m"
        apt update && apt install -y jq
        if [ $? -eq 0 ]; then
            echo -e "\033[0;32m[+] ✅ jq installed successfully\033[0m"
            installed=1
        else
            echo -e "\033[0;31m[!] ❌ Failed to install jq\033[0m"
            return 1
        fi
    else
        echo -e "\033[0;32m[+] ✅ jq already installed\033[0m"
    fi
    
    # Check and install mysql-client
    if ! command -v mysql &> /dev/null; then
        echo -e "\033[0;33m[!] Installing mysql-client...\033[0m"
        apt update && apt install -y mysql-client
        if [ $? -eq 0 ]; then
            echo -e "\033[0;32m[+] ✅ mysql-client installed successfully\033[0m"
            installed=1
        else
            echo -e "\033[0;31m[!] ❌ Failed to install mysql-client\033[0m"
            return 1
        fi
    else
        echo -e "\033[0;32m[+] ✅ mysql-client already installed\033[0m"
    fi
    
    if [ $installed -eq 1 ]; then
        echo -e "\033[0;32m[+] All dependencies are ready\033[0m"
    fi
}

create_allocations() {
    local NODE_ID=$1
    local START_PORT=3000
    local END_PORT=3010
    
    echo -e "\033[0;32m[+] Membuat allocation via database...\033[0m"
    
    # Dapatkan database credentials dari environment
    if [ ! -f ".env" ]; then
        echo -e "\033[0;31m[!] ❌ File .env tidak ditemukan\033[0m"
        return 1
    fi
    
    DB_NAME=$(grep DB_DATABASE .env | cut -d '=' -f2)
    DB_USER=$(grep DB_USERNAME .env | cut -d '=' -f2)
    DB_PASS=$(grep DB_PASSWORD .env | cut -d '=' -f2)
    
    # Validasi database credentials
    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
        echo -e "\033[0;31m[!] ❌ Gagal mendapatkan kredensial database dari .env\033[0m"
        return 1
    fi
    
    # Test database connection
    if ! mysql -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME" 2>/dev/null; then
        echo -e "\033[0;31m[!] ❌ Tidak dapat terhubung ke database\033[0m"
        echo -e "\033[0;33m[!] Pastikan:\033[0m"
        echo -e "\033[0;36m    - Database service sedang berjalan\033[0m"
        echo -e "\033[0;36m    - Kredensial di .env benar\033[0m"
        echo -e "\033[0;36m    - User database memiliki hak akses yang cukup\033[0m"
        return 1
    fi
    
    # Buat allocation untuk port range
    local success_count=0
    local total_ports=$((END_PORT - START_PORT + 1))
    
    for port in $(seq $START_PORT $END_PORT); do
        if mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
            "INSERT INTO allocations (node_id, ip, port, assigned, server_id) VALUES ($NODE_ID, '0.0.0.0', $port, 0, NULL);" 2>/dev/null; then
            success_count=$((success_count + 1))
        else
            echo -e "\033[0;33m[!] Gagal membuat allocation untuk port $port\033[0m"
        fi
    done
    
    # Verifikasi allocation
    local alloc_count=$(mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT COUNT(*) FROM allocations WHERE node_id = $NODE_ID;" 2>/dev/null)
    
    if [ $success_count -gt 0 ]; then
        echo -e "\033[0;32m[+] ✅ Allocation berhasil dibuat:\033[0m"
        echo -e "\033[0;36m    - Port Range: ${START_PORT}-${END_PORT}\033[0m"
        echo -e "\033[0;36m    - Berhasil: ${success_count}/${total_ports} ports\033[0m"
        echo -e "\033[0;36m    - Total allocation node: ${alloc_count}\033[0m"
        echo -e "\033[0;32m[+] IP: 0.0.0.0\033[0m"
    else
        echo -e "\033[0;31m[!] ❌ Gagal membuat semua allocation\033[0m"
        echo -e "\033[0;33m[!] Buat allocation manual via panel web\033[0m"
    fi
    
    # Tampilkan allocations yang berhasil dibuat
    if [ $success_count -gt 0 ]; then
        echo -e ""
        echo -e "\033[0;32m[+] Daftar allocation yang berhasil:\033[0m"
        mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
            "SELECT id, ip, port, assigned FROM allocations WHERE node_id = $NODE_ID ORDER BY port;" 2>/dev/null
    fi
}

# Fungsi bantuan untuk menampilkan informasi node
show_node_info() {
    local NODE_ID=$1
    
    echo -e ""
    echo -e "\033[0;32m[+] Informasi Node:\033[0m"
    php artisan p:node:list --format=json | jq -r ".[] | select(.id == $NODE_ID) | \"   🖥️  Nama: \(.name)\n   🔢 ID: \(.id)\n   📍 Location: \(.location_id)\n   🌐 FQDN: \(.fqdn)\n   💾 Memory: \(.memory) MB\n   💿 Disk: \(.disk) MB\""
}
uninstall_panel() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]                    UNINSTALL PANEL                 [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "


bash <(curl -s https://pterodactyl-installer.se) <<EOF
y
y
y
y
EOF


  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]                 UNINSTALL PANEL SUKSES             [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sleep 2
  clear
  exit 0
}
configure_wings() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]                    CONFIGURE WINGS                 [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  #!/bin/bash

# Minta input token dari pengguna
read -p "Masukkan token Configure menjalankan wings: " wings

eval "$wings"
# Menjalankan perintah systemctl start wings
sudo systemctl start wings

  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]                 CONFIGURE WINGS SUKSES             [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sleep 2
  clear
  exit 0
}
hackback_panel() {
  echo -e "                                                       "
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "${BLUE}[+]                    HACK BACK PANEL                 [+]${NC}"
  echo -e "${BLUE}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  # Minta input dari pengguna
read -p "Masukkan Username Panel: " user
read -p "password login " psswdhb
  #!/bin/bash
cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

# Membuat lokasi baru
php artisan p:user:make <<EOF
yes
hackback@gmail.com
$user
$user
$user
$psswdhb
EOF
  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]                 AKUN TELAH DI ADD             [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sleep 2
  
  exit 0
}
ubahpw_vps() {
  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]                    UBAH PASSWORD VPS       [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
read -p "Masukkan Pw Baru: " pw
read -p "Masukkan Ulang Pw Baru " pw

passwd <<EOF
$pw
$pw

EOF


  echo -e "                                                       "
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "${GREEN}[+]                 GANTI PW VPS SUKSES         [+]${NC}"
  echo -e "${GREEN}[+] =============================================== [+]${NC}"
  echo -e "                                                       "
  sleep 2
  
  exit 0
}
# Main script
display_welcome
install_jq
check_token

while true; do
  clear
  echo -e "                                                                     "
  echo -e "${BLUE}        _,gggggggggg.                                     ${NC}"
  echo -e "${BLUE}    ,ggggggggggggggggg.                                   ${NC}"
  echo -e "${BLUE}  ,ggggg        gggggggg.                                 ${NC}"
  echo -e "${BLUE} ,ggg'               'ggg.                                ${NC}"
  echo -e "${BLUE}',gg       ,ggg.      'ggg:                               ${NC}"
  echo -e "${BLUE}'ggg      ,gg'''  .    ggg       Auto Installer @gudel023 Private   ${NC}"
  echo -e "${BLUE}gggg      gg     ,     ggg      ------------------------  ${NC}"
  echo -e "${BLUE}ggg:     gg.     -   ,ggg       • Telegram : t.me/gudel023     ${NC}"
  echo -e "${BLUE} ggg:     ggg._    _,ggg        • Creadit  : @gudel023 ${NC}"
  echo -e "${BLUE} ggg.    '.'''ggggggp           • Support by @gudel023  ${NC}"
  echo -e "${BLUE}  'ggg    '-.__                                           ${NC}"
  echo -e "${BLUE}    ggg                                                   ${NC}"
  echo -e "${BLUE}      ggg                                                 ${NC}"
  echo -e "${BLUE}        ggg.                                              ${NC}"
  echo -e "${BLUE}          ggg.                                            ${NC}"
  echo -e "${BLUE}             b.                                           ${NC}"
  echo -e "                                                                     "
  echo -e "BERIKUT LIST INSTALL :"
  echo "1. Install theme"
  echo "2. Uninstall theme"
  echo "3. Configure Wings"
  echo "4. Create Node"
  echo "5. Uninstall Panel"
  echo "6. Stellar Theme"
  echo "7. Hack Back Panel"
  echo "8. Ubah Pw Vps"
  echo "x. Exit"
  echo -e "Masukkan pilihan 1/2/x:"
  read -r MENU_CHOICE
  clear

  case "$MENU_CHOICE" in
    1)
      install_theme
      ;;
    2)
      uninstall_theme
      ;;
      3)
      configure_wings
      ;;
      4)
      create_node
      ;;
      5)
      uninstall_panel
      ;;
      6)
      install_themeSteeler
      ;;
      7)
      hackback_panel
      ;;
      8)
      ubahpw_vps
      ;;
    x)
      echo "Keluar dari skrip."
      exit 0
      ;;
    *)
      echo "Pilihan tidak valid, silahkan coba lagi."
      ;;
  esac
done"
