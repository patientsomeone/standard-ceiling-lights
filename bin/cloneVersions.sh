source=$1;
shift;
versions=("${@}")

echo Beginning Version Clone
# Restore cursor on exit
trap cursorReset EXIT
# Hide Cursor
tput civis

# Generate spinner while processing
cursorReset() {
    tput cnorm
}
working() {
    pid=$!

    spin="▖▘▝▗"

    state=0
    # Save Cursor Location
    tput sc

    echo " "
    echo " "

    while kill -0 $pid 2>/dev/null
    do
        state=$(( (state+1) % ${#spin} ))

        printf "   \r${spin:$state:1}"
        # Restore Cursor Location
        tput rc

        sleep .2
    done

    wait $pid
    return $?
}

# Check that Version Folder exists
checkFolder() {
    echo checkFolder
}

# Create Version Folder
createFolder() {
    echo Creating $version
    mkdir "./mod/$version" & working
    wait
}

# Copy from Source
copyMod() {
    echo Deploying to $version
    cp $source $version -r & working
    wait
}

versionLoop() {
    for version in "${versions[@]}"
    do :
        if [ -d "./mod/$version" ]; 
        then
            # echo Copying to $version;
            copyMod;
        else 
            # echo Creating $version;
            createFolder;
            copyMod;
        fi
    done
}

checkSource() {
    if [ -d $source ]; 
    then
        echo Source $source exists, proceeding with copy;
        validSource=true
    else 
        echo Source $source does not exist, exiting;
        validSource=false
    fi
}


execute() {
    checkSource;

    if [ $validSource = true ]
    then
        echo $source is valid, executing Loop;
        versionLoop;
    else
        echo $source does not exist, exiting
    fi;
}

execute;