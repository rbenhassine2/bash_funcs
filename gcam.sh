gcam(){
    if [ $# -eq 0 ]; then
        echo "Error: Function requires a commit message"
        return 1
    fi

    git add .

    if [[ $? -eq 0 ]]; then
        git commit -am "$1"
    fi     
}