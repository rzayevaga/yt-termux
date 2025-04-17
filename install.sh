#!/data/data/com.termux/files/usr/bin/bash

echo -e "\e[93mSistem paketləri yenilənir...\e[0m"
apt update && apt -y upgrade

echo -e "\e[92mTələb olunan alətlər quraşdırılır...\e[0m"
pkg install termux-api figlet python ffmpeg git -y

echo -e "\e[93mStorage icazəsi alınır...\e[0m"
termux-setup-storage
sleep 3

echo -e "\e[92mPython paketləri quraşdırılır (yt-dlp)...\e[0m"
pip install yt-dlp

echo -e "\e[96mYoutube üçün qovluq yaradılır...\e[0m"
mkdir -p ~/storage/shared/Youtube

echo -e "\e[96mYT-DLP konfiqurasiya qovluğu yaradılır...\e[0m"
mkdir -p ~/.config/yt-dlp

echo -e "\e[96mBin qovluğu yaradılır...\e[0m"
mkdir -p ~/bin

echo -e "\e[93mURL açıcı faylı əlavə olunur...\e[0m"
cat > ~/bin/termux-url-opener << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

telegram_bot_token="" # t.me/botfather -dən əldə et.
chat_id="" # bot olan qrup vəya kanalın ID si.

red='\e[91m'; yellow='\e[93m'; blue='\e[34m'; green='\e[92m'; cyan='\e[96m'; resetcol='\e[0m'; bold='\e[1m'

clear
printf "$blue$bold"
echo "       Termux Yükləyici:"
printf "$green"
figlet "coredi"
printf "$resetcol$blue"
echo "    Əlaqə Email:"
printf "$green$bold"
echo "  no-reply@rzayeffdi.tech"
printf "$resetcol$yellow"
echo "_____________________________________"
printf "$cyan$bold"
echo "  1) Yalnız səs (MP3)"
echo "  2) Bütün siyahı (playlist)"
echo "  3) 240p Video"
echo "  4) 360p Video"
echo "  5) 480p Video"
echo "  6) 720p Video"
echo "  7) 1080p Video"
echo "  8) 2K Video"
echo "  9) 4K Video"
echo -e "  0) Əlavə seçimlər (BETA)"
printf "$yellow"
echo "——————————————————————————————————————"
printf "$red"
echo "  1-dən 9-a qədər seçim edin və Enter basın"
printf "$resetcol"

command='--no-warnings --newline -o /data/data/com.termux/files/home/storage/shared/Youtube/%(title)s.%(ext)s -f'
myorder='--no-warnings --newline -o /data/data/com.termux/files/home/storage/shared/Youtube/%(playlist)s/%(playlist_index)s.%(title)s.%(ext)s -f'

read option

if [ "$option" == "0" ]; then
    clear
    echo -e "$cyan Link sayı seçin (maksimum 10):$resetcol"
    echo "1) 2 link"
    echo "2) 4 link"
    echo "3) 6 link"
    echo "4) 8 link"
    echo "5) 10 link"
    read count_choice

    case $count_choice in
    1) total=2 ;;
    2) total=4 ;;
    3) total=6 ;;
    4) total=8 ;;
    5) total=10 ;;
    *) total=2 ;;
    esac

    declare -a link_list=()
    for ((i = 1; i <= total; i++)); do
        echo -ne "$cyan $i-ci linki daxil edin:$resetcol "
        read link
        link_list+=("$link")
    done

    clear
    echo -e "$cyan Keyfiyyət seçimi (1-dən 9-a qədər):$resetcol"
    echo "1) MP3"
    echo "2) Playlist"
    echo "3) 240p"
    echo "4) 360p"
    echo "5) 480p"
    echo "6) 720p"
    echo "7) 1080p"
    echo "8) 2K"
    echo "9) 4K"
    read quality

    for url in "${link_list[@]}"; do
        title=$(yt-dlp --get-title "$url")
        printf "$cyan\nYükləmə başladı: $title\n$resetcol"
        case $quality in
        1 )
        echo "$command ba -x --audio-format mp3" > ~/.config/yt-dlp/config
        ;;
        2 )
        echo "$myorder bestvideo+bestaudio" > ~/.config/yt-dlp/config
        ;;
        3 )
        echo "$command bestvideo[height<=240]+bestaudio/best[height<=240]" > ~/.config/yt-dlp/config
        ;;
        4 )
        echo "$command bestvideo[height<=360]+bestaudio/best[height<=360]" > ~/.config/yt-dlp/config
        ;;
        5 )
        echo "$command bestvideo[height<=480]+bestaudio/best[height<=480]" > ~/.config/yt-dlp/config
        ;;
        6 )
        echo "$command bestvideo[height<=720]+bestaudio/best[height<=720]" > ~/.config/yt-dlp/config
        ;;
        7 )
        echo "$command bestvideo[height<=1080]+bestaudio/best[height<=1080]" > ~/.config/yt-dlp/config
        ;;
        8 )
        echo "$command bestvideo[height<=1440]+bestaudio/best[height<=1440]" > ~/.config/yt-dlp/config
        ;;
        9 )
        echo "$command bestvideo[height<=2160]+bestaudio/best[height<=2160]" > ~/.config/yt-dlp/config
        ;;
        * )
        echo "$command bestvideo+bestaudio/best" > ~/.config/yt-dlp/config
        ;;
        esac

        yt-dlp "$url"
        file_path=$(find ~/storage/shared/Youtube -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        curl -F document=@"$file_path" "https://api.telegram.org/bot$telegram_bot_token/sendDocument?chat_id=$chat_id"
        termux-open "$file_path"
        termux-notification -t "Yükləmə tamamlandı" -c "$title" --sound --vibrate 800 --priority high
    done
    exit
fi

urls=$(echo "$1" | tr ',' '\n')
for url in $urls; do
    title=$(yt-dlp --get-title "$url")
    printf "$cyan\nYükləmə başladı: $title\n$resetcol"
    case $option in
    1 )
    echo "$command ba -x --audio-format mp3" > ~/.config/yt-dlp/config
    ;;
    2 )
    echo "$myorder bestvideo+bestaudio" > ~/.config/yt-dlp/config
    ;;
    3 )
    echo "$command bestvideo[height<=240]+bestaudio/best[height<=240]" > ~/.config/yt-dlp/config
    ;;
    4 )
    echo "$command bestvideo[height<=360]+bestaudio/best[height<=360]" > ~/.config/yt-dlp/config
    ;;
    5 )
    echo "$command bestvideo[height<=480]+bestaudio/best[height<=480]" > ~/.config/yt-dlp/config
    ;;
    6 )
    echo "$command bestvideo[height<=720]+bestaudio/best[height<=720]" > ~/.config/yt-dlp/config
    ;;
    7 )
    echo "$command bestvideo[height<=1080]+bestaudio/best[height<=1080]" > ~/.config/yt-dlp/config
    ;;
    8 )
    echo "$command bestvideo[height<=1440]+bestaudio/best[height<=1440]" > ~/.config/yt-dlp/config
    ;;
    9 )
    echo "$command bestvideo[height<=2160]+bestaudio/best[height<=2160]" > ~/.config/yt-dlp/config
    ;;
    * )
    echo "$command bestvideo+bestaudio/best" > ~/.config/yt-dlp/config
    ;;
    esac

    yt-dlp "$url"
    file_path=$(find ~/storage/shared/Youtube -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    curl -F document=@"$file_path" "https://api.telegram.org/bot$telegram_bot_token/sendDocument?chat_id=$chat_id"
    termux-open "$file_path"
    termux-notification -t "Yükləmə tamamlandı" -c "$title" --sound --vibrate 800 --priority high
done

EOF

chmod +x ~/bin/termux-url-opener
dos2unix ~/bin/termux-url-opener

echo -e "\n\e[92mQuraşdırma tamamlandı!\e[0m"
figlet coredi
