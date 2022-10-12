#!/bin/sh
. ~/.nvm/nvm.sh

# The following shims should not be required, but leaving commented in case requirements arise
# . ~/.profile
# . ~/.bashrc

echo Beginning Environment Cleanup
# Restore cursor on exit
trap cursorReset EXIT
# Hide Cursor
tput civis

intendedNodeVersion=$1;
shift;
files=("${@}");

# Generate spinner while processing
cursorReset() {
    tput cnorm
}
working() {
    pid=$!

    # spin="-\|/"
    # spin="▁▂▃▄▅▆▇█▇▆▅▄▃▂▁"
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


# Returns 0 if Node Version is compatible
versionCompatible() {

    currentNodeVersion=$(node --version)
    isCompatible=false

    echo ------ ------
    echo Checking Node Version Compatibility

    if [ "$currentNodeVersion" = "v$intendedNodeVersion" ];
    then
        echo Active Node Version, $currentNodeVersion is correct;
        isCompatible=true
    else
        echo $currentNodeVersion is does not match, updating to $intendedNodeVersion;
        wait
        isCompatible=false
    fi

    echo ------ ------
}


# sets isAvailable true if Node Version is available in NVM List
versionAvailable() {
    echo ------ ------
    isAvailable=false
    
    availableVersions=($(nvm list));
    isAvail=$(echo "$(nvm list))" | grep -ci $intendedNodeVersion )
    wait

    # echo isAvail: $isAvail

    if [ "$isAvail" -gt "0" ]
    then
        echo Node version $intendedNodeVersion available in NVM
        isAvailable=true
    else
        echo Installing Node version $intendedNodeVersion
    fi
    echo ------ ------
}

installNodeVersion() {
    echo ------ ------
    echo Installing Node version $intendedNodeVersion
    nvm install $intendedNodeVersion
    wait

    versionCompatible
    wait
    echo ------ ------
}

setNodeVersion() {
    nvmAliasAvailable=$(echo "$(nvm)" | grep -ci "nvm alias")

    echo ------ ------
    echo Setting node version $intendedNodeVersion
    nvm use $intendedNodeVersion
    wait

    if [[ $nvmAliasAvailable -gt 0 ]] && [[ -z "$nvmrcVersion" ]]
    then
        echo Setting default NVM Alias
        nvm alias default $intendedNodeVersion
        wait
    else
        echo Skipping NVM Default Alias
    fi

    echo ------ ------
}

runNvm() {
    echo ------ ------
    versionAvailable
    wait

    if [ $isAvailable = true ]
    then
        setNodeVersion
        wait
    else
        installNodeVersion
        wait
    fi

    
    echo ------ ------
}

checkNode() {
    echo ------
    echo Checking current Node version
    versionCompatible

    updateNode=true
    
    if [ $isCompatible = true ]
    then
        updateNode=false
    else
        echo Updating Node Version from $(node --version)
        runNvm
        echo Node Version set
        wait
        versionCompatible

        if [ $isCompatible = true ]
        then
            echo Successfully updated Node Version
            wait
            updateNode=false
        else
            echo Node Version Update Failed. Please retry, or install Node version $intendedNodeVersion manually
            wait
            updateNode=true
        fi
    fi
    
    echo ------
}

removeEntry() {
    shopt -s nullglob
    globbed=($i)
    # echo removeEntry globbed: $globbed
    # echo removeEntry globbed length: "${#globbed[@]}"

    for glob in "${globbed[@]}"
    do :
        if [ -f $glob ] || [ -d $glob ]; 
        then
            echo Removing $glob;

            rm -r $glob & working
        else 
            echo $glob does not exist;
        fi
        wait
    done
    wait

}

processFiles() {
    echo ------
    echo Preparing to remove: ${files[@]}. This may take a few moments...
    for i in "${files[@]}"
    do :
        echo Checking for $i;
        removeEntry
        
    done
    wait
    echo ------
}

stash() {
    echo ------
    echo Stashing any changes to repo;
    git stash;
    wait
    echo ------
}

stashPop() {
    echo ------
    echo Popping stashed changes;
    git stash pop;
    wait
    echo ------
}

checkGit() {
    echo ------
    status=$(git status);
    wait

    echo $(grep "ahead of 'origin/master'" <<< "$status" | wc -l)
    echo $(grep -- "to be committed" <<< "$status"  | wc -l)

    if [ $(grep "ahead of 'origin/master'" <<< "$status" | wc -l) -ge 1 ] || [ $(grep "to be committed" <<< "$status" | wc -l) -ge 1 ] 
    then 
        echo needs stash and pop
        return 0
    fi

    return 1;
    echo ------
}

pullMaster() {
    echo ------
    echo Pulling from Master;
    (git pull origin master --no-rebase && echo Successfully Pulled from Master || echo "Unable to pull from Master") & working
    wait
    echo ------
}

installModules() {
    echo ------
    echo Reinstalling Node Modules
    npm i
    wait
    echo ------
}

processNode() {
    echo Processing Node
    checkNode
    wait

    installModules
    wait
}

fetchNvmrc() {
    echo Fetching version from .nvmrc

    nvmrcVersion=$(cat .nvmrc)

    echo Node Version from .nvmrc $nvmrcVersion will be utilized

    if [ $(grep "v" <<< "$nvmrcVersion" | wc -l) -ge 1 ] 
    then 
        intendedNodeVersion=$(echo $nvmrcVersion | cut -d "v" -f 2)
    else
        intendedNodeVersion=$nvmrcVersion
    fi

    wait
    # echo $intendedNodeVersion

}

execute() {
    echo Files be removed: ${files[@]}

    processFiles
    wait

    # pullMaster
    # wait

    if [ $intendedNodeVersion = false ]
    then
        echo Node processing not requested
    else
        # echo Processing Node Version $intendedNodeVersion
        processNode
    fi
}

if [ $intendedNodeVersion = "nvm" ] && [ -f ".nvmrc" ]
then
    fetchNvmrc
    execute
elif [ ! $intendedNodeVersion = "nvm" ]
then
    execute
else
    echo " --------------------- "
    echo " ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ "
    echo " ↓ ↓ ↓ ↓ ERROR ↓ ↓ ↓ ↓ "
    echo " "
    echo .nvmrc defined by reset execution, but the file does not exist. Exiting
    echo " "
    echo " ↑ ↑ ↑ ↑ ERROR ↑ ↑ ↑ ↑ "
    echo " ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ "
    echo " --------------------- "
    exit 125
fi

echo Reset Complete