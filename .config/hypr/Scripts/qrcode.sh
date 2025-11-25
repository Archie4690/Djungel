qrcode() {
    # Check if an argument was provided
    if [ -z "$1" ]; then
        echo "Error: Please provide a URL or text to encode."
        echo "Usage: qrcode <text_or_url>"
    else
        # Execute the curl command, substituting the input for $1
        curl "qrenco.de/$1"
    fi
}