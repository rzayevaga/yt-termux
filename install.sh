#!/data/data/com.termux/files/usr/bin/bash

# Rəng kodları
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
PURPLE='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
BOLD='\033[1m'
RESET='\033[0m'

# Progress bar funksiyası
progress_bar() {
    local duration=$1
    local steps=50
    local step_delay=$(echo "scale=3; $duration/$steps" | bc -l)
    
    echo -ne "${CYAN}[${RESET}"
    for ((i=0; i<steps; i++)); do
        echo -ne "█"
        sleep $step_delay
    done
    echo -ne "${CYAN}]${RESET}\n"
}

# Animasiya funksiyası
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Header
clear
echo -e "${PURPLE}${BOLD}"
echo "╔════════════════════════════════════════════════╗"
echo "║           TERMUX PREMIUM DOWNLOADER           ║"
echo "║                by Rzayeff Agha                ║"
echo "║           https://rzayeffdi.tech              ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Sistem yoxlaması
echo -e "${YELLOW}${BOLD}[1/6]${RESET} ${CYAN}Sistem yoxlanılır...${RESET}"
if ! command -v pkg &> /dev/null; then
    echo -e "${RED}❌ Termux pkg meneceri tapılmadı!${RESET}"
    exit 1
fi

# Paketlərin yenilənməsi
echo -e "${YELLOW}${BOLD}[2/6]${RESET} ${CYAN}Sistem paketləri yenilənir...${RESET}"
apt update && apt -y upgrade

# Lazımlı paketlərin quraşdırılması
echo -e "${YELLOW}${BOLD}[3/6]${RESET} ${CYAN}Tələb olunan alətlər quraşdırılır...${RESET}"
pkg install -y termux-api figlet python ffmpeg git wget curl jq

# Storage icazəsi
echo -e "${YELLOW}${BOLD}[4/6]${RESET} ${CYAN}Storage icazəsi alınır...${RESET}"
termux-setup-storage
sleep 2

# Python paketləri
echo -e "${YELLOW}${BOLD}[5/6]${RESET} ${CYAN}Python paketləri quraşdırılır...${RESET}"
pip install --upgrade pip
pip install yt-dlp speedtest-cli

# Qovluq strukturunun yaradılması
echo -e "${YELLOW}${BOLD}[6/6]${RESET} ${CYAN}Qovluq strukturu yaradılır...${RESET}"
mkdir -p ~/storage/shared/Downloader/{Youtube,Instagram,Tiktok,Music,Videos}
mkdir -p ~/.config/yt-dlp
mkdir -p ~/bin

# Telegram konfiqurasiyası (optional)
echo -e "\n${GREEN}${BOLD}🤖 TELEGRAM BOT KONFİQURASİYASI${RESET}"
echo -e "${YELLOW}Telegram bildirişləri üçün bot tokeni əlavə etmək istəyirsiniz?${RESET}"
echo -e "${CYAN}1) Bəli, quraşdır${RESET}"
echo -e "${CYAN}2) Xeyr, keç${RESET}"
read -p "Seçiminiz (1/2): " telegram_choice

if [ "$telegram_choice" = "1" ]; then
    read -p "Bot Token: " telegram_bot_token
    read -p "Chat ID: " chat_id
    echo -e "${GREEN}✅ Telegram konfiqurasiyası qeyd edildi!${RESET}"
else
    telegram_bot_token=""
    chat_id=""
    echo -e "${YELLOW}⚠️ Telegram bildirişləri deaktiv edildi${RESET}"
fi

# Əsas yükləyici skripti
cat > ~/bin/termux-url-opener << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Rəng kodları
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
PURPLE='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
BOLD='\033[1m'
RESET='\033[0m'

# Konfiqurasiya
CONFIG_DIR="$HOME/.config/termux-downloader"
TELEGRAM_CONFIG="$CONFIG_DIR/telegram.conf"

# Telegram funksiyaları
init_telegram() {
    if [ -f "$TELEGRAM_CONFIG" ]; then
        source "$TELEGRAM_CONFIG"
    fi
}

send_telegram_notification() {
    local message="$1"
    local file_path="$2"
    
    if [ -n "$telegram_bot_token" ] && [ -n "$chat_id" ]; then
        if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            curl -F document=@"$file_path" "https://api.telegram.org/bot$telegram_bot_token/sendDocument?chat_id=$chat_id&caption=$message" >/dev/null 2>&1
        else
            curl -s "https://api.telegram.org/bot$telegram_bot_token/sendMessage?chat_id=$chat_id&text=$message" >/dev/null 2>&1
        fi
    fi
}

# Progress monitor
progress_monitor() {
    local url="$1"
    local quality="$2"
    local start_time=$(date +%s)
    
    while true; do
        if ps aux | grep -v grep | grep -q "$url"; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            echo -ne "${CYAN}⏳ Yüklənir... ${elapsed}s${RESET}\r"
            sleep 1
        else
            break
        fi
    done
}

# Real-time sürət göstəricisi
speed_monitor() {
    local file_path="$1"
    local last_size=0
    local last_time=$(date +%s.%N)
    
    while [ ! -f "$file_path" ] || [ $(stat -c%s "$file_path" 2>/dev/null || echo 0) -eq 0 ]; do
        sleep 1
    done
    
    while ps aux | grep -v grep | grep -q "yt-dlp"; do
        if [ -f "$file_path" ]; then
            local current_size=$(stat -c%s "$file_path")
            local current_time=$(date +%s.%N)
            local size_diff=$((current_size - last_size))
            local time_diff=$(echo "$current_time - $last_time" | bc -l)
            
            if [ $size_diff -gt 0 ] && [ $(echo "$time_diff > 0" | bc -l) -eq 1 ]; then
                local speed_kbs=$(echo "scale=2; $size_diff / $time_diff / 1024" | bc -l)
                local speed_mbs=$(echo "scale=2; $speed_kbs / 1024" | bc -l)
                
                if [ $(echo "$speed_mbs > 1" | bc -l) -eq 1 ]; then
                    echo -ne "${GREEN}🚀 Sürət: ${speed_mbs} MB/s${RESET}\r"
                else
                    echo -ne "${GREEN}🚀 Sürət: ${speed_kbs} KB/s${RESET}\r"
                fi
            fi
            
            last_size=$current_size
            last_time=$current_time
        fi
        sleep 2
    done
}

# Video məlumatları
get_video_info() {
    local url="$1"
    echo -e "\n${CYAN}📊 Video məlumatları alınır...${RESET}"
    
    local info=$(yt-dlp --get-title --get-duration --get-format "$url" 2>/dev/null)
    local title=$(echo "$info" | head -1)
    local duration=$(echo "$info" | head -2 | tail -1)
    local format=$(echo "$info" | tail -1)
    
    echo -e "${GREEN}📹 Başlıq:${RESET} $title"
    echo -e "${GREEN}⏱️ Müddət:${RESET} $duration"
    echo -e "${GREEN}📦 Format:${RESET} $format"
}

# Download funksiyası
download_content() {
    local url="$1"
    local quality="$2"
    local format="$3"
    local output_template="/data/data/com.termux/files/home/storage/shared/Downloader/%(title)s.%(ext)s"
    
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║               DOWNLOAD STARTED                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    get_video_info "$url"
    
    echo -e "\n${YELLOW}⬇️ Yükləmə başladı...${RESET}"
    
    # Başlanğıc zamanı
    local start_time=$(date +%s)
    
    # Telegram bildirişi
    send_telegram_notification "🚀 Yükləmə başladı: $url"
    
    # Format seçimi
    case $quality in
        "mp3")
            format_args="-x --audio-format mp3 --audio-quality 0"
            output_template="/data/data/com.termux/files/home/storage/shared/Downloader/Music/%(title)s.%(ext)s"
            ;;
        "playlist")
            format_args="-f bestvideo+bestaudio"
            output_template="/data/data/com.termux/files/home/storage/shared/Downloader/Youtube/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
            ;;
        "240"|"360"|"480"|"720"|"1080"|"1440"|"2160")
            format_args="-f bestvideo[height<=$quality]+bestaudio/best[height<=$quality]"
            ;;
        "best")
            format_args="-f bestvideo+bestaudio"
            ;;
        *)
            format_args="-f bestvideo+bestaudio/best"
            ;;
    esac
    
    # Xüsusi format üçün
    if [ "$format" = "mp4" ]; then
        format_args+=" --merge-output-format mp4"
    fi
    
    # Yükləmə əmri
    yt-dlp $format_args -o "$output_template" --no-warnings --newline \
        --add-metadata --embed-thumbnail --concurrent-fragments 5 "$url" &
    
    local download_pid=$!
    
    # Progress monitoru başlat
    progress_monitor "$url" "$quality" &
    local progress_pid=$!
    
    # Sürət monitoru başlat
    speed_monitor "$(find ~/storage/shared/Downloader -name "*.mp4" -o -name "*.mp3" 2>/dev/null | head -1)" &
    local speed_pid=$!
    
    # Yükləmənin bitməsini gözlə
    wait $download_pid
    
    # Monitor proseslərini dayandır
    kill $progress_pid $speed_pid 2>/dev/null
    
    # Bitmə zamanı
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    # Faylın yolu
    local file_path=$(find ~/storage/shared/Downloader -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        local file_size=$(stat -c%s "$file_path")
        local size_mb=$(echo "scale=2; $file_size / (1024*1024)" | bc -l)
        
        echo -e "\n${GREEN}✅ Yükləmə tamamlandı!${RESET}"
        echo -e "${GREEN}📁 Fayl:${RESET} $(basename "$file_path")"
        echo -e "${GREEN}📊 Ölçü:${RESET} ${size_mb} MB"
        echo -e "${GREEN}⏱️ Vaxt:${RESET} ${total_time} saniyə"
        
        # Telegram bildirişi
        send_telegram_notification "✅ Yükləmə tamamlandı: $(basename "$file_path")" "$file_path"
        
        # Bildiriş
        termux-notification -t "✅ Yükləmə tamamlandı" -c "$(basename "$file_path")" \
            --button1 "Aç" --button1-action "termux-open '$file_path'" \
            --button2 "Paylaş" --button2-action "termux-share '$file_path'" \
            --sound --vibrate 1000 --priority high
        
        # Faylı aç
        termux-open "$file_path"
    else
        echo -e "\n${RED}❌ Yükləmə uğursuz oldu!${RESET}"
        send_telegram_notification "❌ Yükləmə uğursuz oldu: $url"
    fi
}

# Manual download funksiyası
manual_download() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║               MANUAL DOWNLOAD                 ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    read -p "📥 URL daxil edin: " manual_url
    
    if [ -z "$manual_url" ]; then
        echo -e "${RED}❌ URL daxil edilməyib!${RESET}"
        return 1
    fi
    
    show_quality_menu "$manual_url"
}

# Sürət testi
speed_test() {
    echo -e "\n${CYAN}🌐 İnternet sürəti yoxlanılır...${RESET}"
    speedtest-cli --simple
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Sürət testi tamamlandı${RESET}"
    else
        echo -e "${RED}❌ Sürət testi uğursuz oldu${RESET}"
    fi
}

# Keyfiyyət menyusu
show_quality_menu() {
    local url="$1"
    
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║              QUALITY SELECTION                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    echo -e "${CYAN}${BOLD}📥 Yükləmə seçimləri:${RESET}"
    echo -e "${GREEN}1) 🎵 MP3 (Yalnız səs)"
    echo -e "2) 📋 Playlist (Bütün siyahı)"
    echo -e "3) 📹 240p Video"
    echo -e "4) 📹 360p Video" 
    echo -e "5) 📹 480p Video"
    echo -e "6) 📹 720p HD Video"
    echo -e "7) 📹 1080p Full HD Video"
    echo -e "8) 📹 2K Video"
    echo -e "9) 📹 4K Ultra HD Video"
    echo -e "10) 🚀 Əlavə seçimlər (Premium)"
    echo -e "11) 🌐 İnternet sürəti testi"
    echo -e "12) 📥 Manual URL daxil et"
    echo -e "0) ❌ Çıxış${RESET}"
    echo -e "${YELLOW}————————————————————————————————————————————${RESET}"
    
    read -p "🔄 Seçiminizi daxil edin (0-12): " main_option
    
    case $main_option in
        1) download_content "$url" "mp3" ;;
        2) download_content "$url" "playlist" ;;
        3) download_content "$url" "240" ;;
        4) download_content "$url" "360" ;;
        5) download_content "$url" "480" ;;
        6) download_content "$url" "720" ;;
        7) download_content "$url" "1080" ;;
        8) download_content "$url" "1440" ;;
        9) download_content "$url" "2160" ;;
        10) show_premium_menu "$url" ;;
        11) speed_test ;;
        12) manual_download ;;
        0) echo -e "${YELLOW}👋 Sağ olun!${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ Yanlış seçim!${RESET}"; show_quality_menu "$url" ;;
    esac
}

# Premium menyu
show_premium_menu() {
    local url="$1"
    
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║               PREMIUM FEATURES                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    echo -e "${CYAN}${BOLD}🚀 Premium Seçimlər:${RESET}"
    echo -e "${GREEN}1) 🔄 Çoxlu link yüklə (Batch)"
    echo -e "2) ⚡ Ən yüksək keyfiyyət"
    echo -e "3) 🎞️ Yalnız video (səssiz)"
    echo -e "4) 🎵 Yalnız səs (audio)"
    echo -e "5) 📊 Video məlumatlarını göstər"
    echo -e "6) 🎯 Xüsusi format (MP4/WEBM)"
    echo -e "0) ↩️ Əsas menyuya qayıt${RESET}"
    
    read -p "💎 Seçiminiz: " premium_option
    
    case $premium_option in
        1) batch_download ;;
        2) download_content "$url" "best" ;;
        3) download_content "$url" "videoonly" ;;
        4) download_content "$url" "audioonly" ;;
        5) get_video_info "$url" ;;
        6) custom_format_download "$url" ;;
        0) show_quality_menu "$url" ;;
        *) echo -e "${RED}❌ Yanlış seçim!${RESET}"; show_premium_menu "$url" ;;
    esac
}

# Batch download
batch_download() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║               BATCH DOWNLOAD                  ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    read -p "🔢 Link sayı (max 10): " count
    
    if ! [[ "$count" =~ ^[1-9]$|^10$ ]]; then
        echo -e "${RED}❌ 1-10 arası rəqəm daxil edin!${RESET}"
        return 1
    fi
    
    declare -a urls=()
    for ((i=1; i<=count; i++)); do
        read -p "📥 $i-ci link: " url
        urls+=("$url")
    done
    
    echo -e "${CYAN}📊 Keyfiyyət seçin (1-9):${RESET}"
    read -p "🔄 Seçim: " quality
    
    for url in "${urls[@]}"; do
        if [ -n "$url" ]; then
            download_content "$url" "$quality"
        fi
    done
}

# Xüsusi format download
custom_format_download() {
    local url="$1"
    
    echo -e "${CYAN}🎯 Format seçin:${RESET}"
    echo -e "${GREEN}1) MP4"
    echo -e "2) WEBM"
    echo -e "3) MKV${RESET}"
    
    read -p "🔄 Seçim: " format_choice
    
    case $format_choice in
        1) download_content "$url" "best" "mp4" ;;
        2) download_content "$url" "best" "webm" ;;
        3) download_content "$url" "best" "mkv" ;;
        *) download_content "$url" "best" "mp4" ;;
    esac
}

# Əsas proqram
main() {
    init_telegram
    
    # Əgər URL parametr kimi verilibsə
    if [ $# -gt 0 ]; then
        url="$1"
        show_quality_menu "$url"
    else
        # Manual mod
        manual_download
    fi
}

# Skripti başlat
main "$@"

EOF

# Manual downloader skripti
cat > ~/bin/ydl << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
~/bin/termux-url-opener manual
EOF

# İcazələrin verilməsi
chmod +x ~/bin/termux-url-opener
chmod +x ~/bin/ydl
dos2unix ~/bin/termux-url-opener ~/bin/ydl

# Konfiqurasiya qovluğu
mkdir -p ~/.config/termux-downloader
if [ -n "$telegram_bot_token" ] && [ -n "$chat_id" ]; then
    cat > ~/.config/termux-downloader/telegram.conf << EOF
telegram_bot_token="$telegram_bot_token"
chat_id="$chat_id"
EOF
fi

# Quraşdırmanın tamamlanması
clear
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════╗"
echo "║          QURAŞDIRMA TAMAMLANDI!              ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${GREEN}✅ Bütün paketlər uğurla quraşdırıldı!${RESET}"
echo -e "\n${CYAN}${BOLD}🚀 İSTİFADƏ TƏLİMATI:${RESET}"
echo -e "${YELLOW}• YouTube/TikTok/Instagram linklərini Termux-a paylaşın"
echo -e "• Əl ilə yükləmə üçün: ${GREEN}ydl${YELLOW} yazın"
echo -e "• Fayllar: ${GREEN}~/storage/shared/Downloader/${YELLOW} qovluğundadır"
echo -e "• Premium funksiyalar: Çoxlu yükləmə, sürət testi, real-time monitor${RESET}"

echo -e "\n${PURPLE}${BOLD}"
figlet "Rzayeffdi"
echo -e "${RESET}"

echo -e "${BLUE}📧 Email: ${GREEN}no-reply@rzayeffdi.tech${RESET}"
echo -e "${BLUE}🌐 Website: ${GREEN}https://rzayeffdi.tech${RESET}"
echo -e "\n${GREEN}🎉 Hazırsınız! İndi video/musiqi yükləyə bilərsiniz!${RESET}"
