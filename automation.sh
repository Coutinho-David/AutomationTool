
show_help() {
    echo "Usage: ./automation.sh [OPTIONS] domain"
    echo ""
    echo "Options:"
    echo "  -h               Show this help message and exit"
    echo "  -r  <domain>     Recon     Perform recon on the target domain"
    echo "  -f  <domain>     FUZZ      Use FFUF to fuzz domain"
    exit 0
}

echo "Starting"

recon=false
fuzz=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h)
            show_help
            ;;
        -r)
            recon=true
            shift
            ;;
        -f)
            fuzz=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            ;;
        *)
            domain="$1"
            shift
            ;;
    esac
done



if [ -z "$domain" ]; then
    echo "Error: No domain specified. Use the domain as the last argument."
    echo "For help, run: ./automation.sh -h"
    exit 1
fi


if [ "$recon" = true ]; then
    echo "Performing Recon on $domain"

    sleep 1.5

    echo "----------------------------------------------------------------
                                    WHOIS"
    whois $domain

    echo "-----------------------------------------------------------------
                                    HOST "
    host $domain

    echo "----------------------------------------------------------------------"
    echo "SUBFINDER SCAN"

    subfinder -d $domain -o "subfinderScan.txt"

    echo "----------------------------------------------------------------------"
    echo "SUBLISTER SCAN"

    python3 -m sublist3r -d $domain -o "sublist3rScan.txt"

    echo "----------------------------------------------------------------------"
    echo "ASSET FINDER SCAN"

    ~/go/bin/assetfinder $domain -subs-only > "assetfinderScan.txt"

    echo "----------------------------------------------------------------------"
    echo "crt.sh SCAN"

    curl "https://crt.sh?q=$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > crt.txt

    cat "crt.txt" "subfinderScan.txt" "sublist3rScan.txt" "assetfinderScan.txt" | sort | uniq > "allDomains.txt"

    ~/go/bin/httpx -l "allDomains.txt" -sc -ip -td -server --follow-redirects -title -o "HttpxAllDomains.txt"
    ~/go/bin/gowitness scan file -f "allDomains.txt"

    read -p "Do you wish to delete previous scan files? [Except for final](Y/n): " choice
    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        rm -f subfinderScan.txt sublist3rScan.txt assetfinderScan.txt
        echo "Deleted previous scan files..."
    else
        echo "Previous scan files were not deleted."
    fi
fi


    echo "----------------------------------------------------------------------"
    echo "subzy SCAN"

    ~/go/bin/subzy run --targets "allDomains.txt" --output "subzy.txt"

    echo "----------------------------------------------------------------------"
    echo "nuclei SCAN for subdomain takeover"

    nuclei -list "allDomains.txt" -t /Users/cdm/xSTF/tools/nuclei-templates/nuclei-templates/http/takeovers/

if [[ "$fuzz" = true ]]; then
    echo "Running FFUF fuzzing on $domain..."
    sleep 1.5
    read -p "Fuzzing for directories, subdomains, files or extensions? (dir/sub/fil/ext) " choice
    if [[ "$choice" = "dir" ]]; then
        ffuf -w /Users/cdm/xSTF/tools/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt:FUZZ -u "https://$domain/FUZZ"
    elif [[ "$choice" = "sub" ]]; then
        ffuf -w /Users/cdm/xSTF/tools/SecLists/Discovery/DNS/subdomains-top1million-110000.txt:FUZZ -u "https://FUZZ.$domain" -fc 404,403
    elif [[ "$choice" = "fil" ]]; then
        read -p "What are the file extensions eg: php, aspx, html, etc...? IF UNKNOWN RUN script with ext" ext
        ffuf -w /Users/cdm/xSTF/tools/SecLists/Discovery/DNS/namelist.txt:FUZZ -u "https://$domain/FUZZ.$ext"
    elif [[ "$choice" = "ext" ]]; then
        ffuf -w /Users/cdm/xSTF/tools/SecLists/Discovery/Web-Content/web-extensions-big.txt:FUZZ -u "https://$domain/indexFUZZ"
    else
        echo "No option selected"
        ./automation.sh -h
        exit 1
    fi
fi
