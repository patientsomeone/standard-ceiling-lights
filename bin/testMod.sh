#!/bin/bash

sourcePath=$1
deploymentPath=$2
forceReset=$3

echo Beginning Test Deployment

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
echoArray() {
    for msg in ${echArr[@]}
    do
        echo $msg
    done
}

# Validate that Folder Exists
exists() {
    echo Validating $pathToValidate
    if [ -d "$pathToValidate" ] || [ -f "$pathToValidate" ];
    then
        # echo Path $pathToValidate exists, proceeding...;
        validPath=true
    else 
        # echo Source $source does not exist, exiting;
        validPath=false
    fi
}

checkPaths() {
    pathsToCheck=("$sourcePath" "$deploymentPath")

    echArr=()
    # echo echArr length ${#echArr[@]}
    echo pathsToCheck ${pathsToCheck[@]}

    # for ((i = 0; i < ${#pathsToCheck[@]}; i++))
    # do
    #     pathToValidate="${pathsToCheck[$i]}"

    #     echo toCheck "${pathsToCheck[$i]}"

    #     echo checking $pathToValidate

    #     exists
    #     wait

    #     if [ $validPath != true ]
    #     then
    #         echArr=(${echArr[@]} $pathToValidate)
    #     fi
    # done

    for pathToValidate in "${pathsToCheck[@]}"
    do
        exists
        wait

        if [ $validPath != true ]
        then
            echArr=(${echArr[@]} $pathToValidate)
        fi
    done

    # echo echArr length ${#echArr[@]}

    if [ ${#echArr[@]} -gt 0 ]
    then
        echo  
        echo  
        echo The following paths did not exist
        # echo ${echArr[@]}
        echoArray
        echo  
        echo  
        echo Unable to complete
    fi

    return ${#echArr[@]}
}

# Copy contents of Source Path to Deployment Path
# Copy from Source
deploy() {
    echo Deploying to $deploymentPath from $sourcePath
    
    cp -r "$sourcePath/." "$deploymentPath/" & working
    wait
}

reset() {
    rm -r "$deploymentPath/**" && echo Successfully cleaned deployment folder || echo failed to clean deployment folder
    # bash "./bin/resetEnv.sh" "false" "$deploymentPath/**" && echo Successfully cleaned deployment folder || echo failed to clean deployment folder
}

shouldReset() {
    if [ $forceReset = true ]
    then
        return 0
    else
        return 1
    fi
    wait
}

pathChecker() {
    # Validate that source and deployment exist before executing
    checkPaths && return 0 || (echo Missing Source or Destination & return 1)
}

resetChecker() {
    # If 3rd argument is true, clean up the deployment folder
    shouldReset && reset
}

pathChecker && resetChecker && deploy && echo  && echo Successfully Deployed to $deploymentPath || (echo  && echo Failed to execute Deployment)