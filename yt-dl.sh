#!/bin/bash

# YouTube Downloader Script
# Usage: ./youtube-dl.sh or ./youtube-dl.sh <youtube_url>

# Configuration
DOWNLOAD_DIR="$HOME/Downloads/Youtube"  # Change this to your preferred directory
FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"  # Max 1080p, fallback to best available
SUBTITLES="--write-subs --write-auto-subs --sub-lang en,es,fr"  # Download subtitles
THUMBNAILS="--write-thumbnail --convert-thumbnails jpg"
METADATA="--add-metadata --embed-metadata --embed-thumbnail"
COOKIES="--cookies-from-browser chrome"  # Optional: use cookies from browser

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Function to display usage
usage() {
    echo "================================================"
    echo "YouTube Downloader Script"
    echo "================================================"
    echo "Usage:"
    echo "  Method 1: Run script and paste URL when prompted"
    echo "  Method 2: ./youtube-dl.sh <youtube_url>"
    echo "  Method 3: ./youtube-dl.sh (and edit URLS.txt)"
    echo ""
    echo "Features:"
    echo "  • Downloads single videos or entire playlists"
    echo "  • Maximum 1080p quality"
    echo "  • Downloads subtitles (if available)"
    echo "  • Saves thumbnails"
    echo "  • Preserves video metadata"
    echo "================================================"
}

# Function to download from URL
download_url() {
    local url="$1"
    
    echo "Starting download: $url"
    echo "Saving to: $DOWNLOAD_DIR"
    echo "----------------------------------------"
    
    cd "$DOWNLOAD_DIR"
    
    # Download using yt-dlp with specified options
    yt-dlp \
        $SUBTITLES \
        $THUMBNAILS \
        $METADATA \
        $COOKIES \
        --output "%(uploader)s/%(playlist_title|)s%(playlist_index|)s/%(title)s.%(ext)s" \
        --format "$FORMAT" \
        --merge-output-format "mkv" \
        --ignore-errors \
        --no-overwrites \
        --progress \
        --console-title \
        "$url"
    
    if [ $? -eq 0 ]; then
        echo "----------------------------------------"
        echo "✓ Download completed successfully!"
        echo "Files saved in: $DOWNLOAD_DIR"
    else
        echo "----------------------------------------"
        echo "✗ Download failed. Please check the URL and try again."
    fi
}

# Function to download from URLS.txt file
download_from_file() {
    if [ ! -f "URLS.txt" ]; then
        echo "URLS.txt file not found. Creating one with instructions..."
        cat > URLS.txt << EOF
# Paste YouTube URLs here (one per line)
# Example:
# https://www.youtube.com/watch?v=VIDEO_ID
# https://www.youtube.com/playlist?list=PLAYLIST_ID
# https://youtu.be/VIDEO_ID

# Add your URLs below this line:

EOF
        echo "Created URLS.txt. Please add URLs to the file and run the script again."
        exit 0
    fi
    
    echo "Found URLS.txt. Starting batch download..."
    echo "================================================"
    
    local count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi
        
        count=$((count + 1))
        echo "Downloading URL $count: $line"
        echo "----------------------------------------"
        download_url "$line"
        echo ""
    done < "URLS.txt"
    
    if [ $count -eq 0 ]; then
        echo "No valid URLs found in URLS.txt"
        echo "Please add URLs to the file and try again."
    else
        echo "Batch download completed!"
    fi
}

# Function to install yt-dlp if not found
install_ytdlp() {
    echo "yt-dlp not found. Installing..."
    
    # Check package manager and install
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y yt-dlp ffmpeg
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y yt-dlp ffmpeg
    elif command -v yum &> /dev/null; then
        sudo yum install -y yt-dlp ffmpeg
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy yt-dlp ffmpeg
    elif command -v brew &> /dev/null; then
        brew install yt-dlp ffmpeg
    else
        echo "Package manager not recognized. Installing via pip..."
        pip3 install yt-dlp
        # Install ffmpeg based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install ffmpeg
        else
            echo "Please install ffmpeg manually:"
            echo "Ubuntu/Debian: sudo apt install ffmpeg"
            echo "Fedora: sudo dnf install ffmpeg"
            echo "Arch: sudo pacman -S ffmpeg"
        fi
    fi
    
    echo "Installation complete!"
}

# Main script logic
main() {
    # Check if yt-dlp is installed
    if ! command -v yt-dlp &> /dev/null; then
        install_ytdlp
    fi
    
    # Show usage if help flag is used
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Create a desktop shortcut for easy access
    if [[ "$1" == "--create-shortcut" ]]; then
        echo "Creating desktop shortcut..."
        SHORTCUT="$HOME/Desktop/YouTube Downloader.desktop"
        cat > "$SHORTCUT" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=YouTube Downloader
Comment=Download YouTube videos and playlists
Exec=$PWD/$(basename "$0")
Icon=video-x-generic
Terminal=true
Categories=Network;
EOF
        chmod +x "$SHORTCUT"
        echo "Shortcut created on Desktop!"
        exit 0
    fi
    
    # Display header
    echo "================================================"
    echo "YouTube Downloader"
    echo "================================================"
    
    # Case 1: URL provided as argument
    if [ -n "$1" ]; then
        download_url "$1"
    
    # Case 2: URLS.txt exists in current directory
    elif [ -f "URLS.txt" ]; then
        echo "URLS.txt found in current directory."
        read -p "Do you want to download from URLS.txt? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            download_from_file
        else
            # Fall through to interactive mode
            echo "Continuing with interactive mode..."
        fi
    fi
    
    # Case 3: Interactive mode (no arguments or URLS.txt not used)
    if [ $# -eq 0 ] || [[ ! "$choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Select mode:"
        echo "1) Enter YouTube URL now"
        echo "2) Download from URLS.txt file"
        echo "3) Create URLS.txt template"
        echo "4) View usage instructions"
        echo "5) Exit"
        echo ""
        
        read -p "Enter choice (1-5): " mode
        
        case $mode in
            1)
                read -p "Enter YouTube URL: " url
                if [ -n "$url" ]; then
                    download_url "$url"
                else
                    echo "No URL provided. Exiting."
                fi
                ;;
            2)
                download_from_file
                ;;
            3)
                if [ ! -f "URLS.txt" ]; then
                    download_from_file  # This creates the file
                else
                    echo "URLS.txt already exists."
                fi
                ;;
            4)
                usage
                ;;
            5)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
