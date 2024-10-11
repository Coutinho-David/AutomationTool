#!/usr/bin/bash

show_help() {
    echo "Usage: ./automation.sh [OPTIONS] domain"
    echo ""
    echo "Options:"
    echo "  -h                Show this help message and exit"
    echo "  -r      Recon     Do Recon on the target domain"
    echo "  -f      FUZZ      Use FFUF to fuzz domain"
    exit 0
}

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
    whois -H $domain

    echo "-----------------------------------------------------------------
                                    HOST " 
    host $domain

    echo "----------------------------------------------------------------------"
    echo "SUBFINDER SCAN"

    subfinder -d $domain -o "subfinderScan.txt"

    echo "----------------------------------------------------------------------"
    echo "SUBLISTER SCAN"

    sublist3r -d $domain -o "sublist3rScan.txt"
    

    httpx-toolkit -l "subfinderScan.txt" -sc -ip -td -server --follow-redirects -title -o "HttpxScanFinder.txt"
    httpx-toolkit -l "sublist3rScan.txt" -sc -ip -td -server --follow-redirects -title -o "HttpxScanList3r.txt"

    cat "HttpxScanFinder.txt" "HttpxScanList3r.txt" | sort | uniq > "final.txt"

    echo "--------------------------------------------------------------------------------------------------~"
    echo "Combined and deduplicated domains saved to final.txt"


    read -p "Do you wish to delete previous scan files? [Except for final](Y/n): " choice

    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        rm -f subfinderScan.txt sublist3rScan.txt HttpxScanFinder.txt HttpxScanList3r.txt
        echo "Deleted previous scan files..."
    else
        echo "Previous scan files were not deleted."
    fi

    echo "You can GREP final.txt for status codes: 

        1xx informational response
        2xx success
        3xx redirection
        4xx client errors

        200 : OK
        204 : NO CONTENT
        301 : MOVED PERMANENTLY 
        401 : UNAUTHORIZED
        403 : FORBIDDEN
        404 : NOT FOUND
        405 : METHOD NOT ALLOWED 

        etc... visit https://en.wikipedia.org/wiki/List_of_HTTP_status_codes for more info"



    read -p "Do you wish to delete previous scan files? [Except for final](Y/n): " choice
fi


if [ "$fuzz" = true ]; then 
    echo "Running FFUF fuzzing on $domain..."
    sleep 1.5
fi










