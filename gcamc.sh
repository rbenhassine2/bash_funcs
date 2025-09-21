gcamc(){
    git add .

    if [[ $? -eq 0 ]]; then
        git commit -am "checkpoint `date -Im -u`"
    fi     
}