#!/bin/bash

PROGRAMNAME=$0

function usage {    
    echo "multi_git_tool is a simple git tool to manage multiple repositories."
    echo "The tool operates on all subdierectories to a provided path or from the env variable GITREPOPATH."
    echo
    echo "Usage: multi_git_tool.sh [-p] <path/to/repo> [-s] [-e] <repo_exclude_list> [-c] <command1> <command2> ..."
    echo "* -p|--path   : provide path to repo, else Will use GITREPOPATH variable"
    echo "* -e|--exclude: list of repo names to exclude"
    echo "* -s|--status : status mode"
    echo "* -c|--command: commands mode"
    echo
    echo "command shortcuts:"
    echo "* s = status"
    echo "* p = pull"
    echo "* f = fetch"
    echo "* scp = status, checkout master, pull"
    echo "* rcp = reset --hard, ceckout master, pull"
    exit 1
}


function command_mode {
    ## calculate # of commands to run
    TOTAL_COMMANDS=0
    for GIT_COMMAND in "${GIT_COMMANDS[@]}"; do # access each element of array
      TOTAL_COMMANDS=$(($TOTAL_COMMANDS+1))
    done    

    if [ "$TOTAL_COMMANDS" == 0 ]; then
        echo "Error. No commands provided."
        exit 1
    fi
    
    echo -e "\033[1;33mRunning $TOTAL_COMMANDS commands:\033[0;0m"          
    for GIT_COMMAND in "${GIT_COMMANDS[@]}"; do # access each element of array
      echo -e "\033[3;33m   git $GIT_COMMAND\033[0;0m"
    done      
    echo 

    read -p "Press enter to continue"

    ## For each git repo found, run all commands
    GIT_DIR_NUM=0
    for DIR in $DIRS ; do
        GIT_DIR_NUM=$(($GIT_DIR_NUM+1))
        REPO_NAME=$(echo $DIR | rev | cut -d/ -f1 | rev)
        if [[ " ${EXCLUDED_REPOS} " == *" ${REPO_NAME} "* ]]; then
            echo -e "\033[4;31m(repo $GIT_DIR_NUM/$TOTAL_GIT_DIRS) Exluding repo $DIR\033[0;0m"
            echo 
            echo -e "\033[0;32m-=-=-=-=-=-=-=-=-=-=-=-=-=-\033[0;0m"
            continue
        fi
        cd $PROVIDED_REPO_PATH/$DIR  
        CURRENT_COMMAND=1
        for GIT_COMMAND in "${GIT_COMMANDS[@]}"; do # access each element of array
            echo -e "\033[4;32m(repo $GIT_DIR_NUM/$TOTAL_GIT_DIRS) $DIR -> ($CURRENT_COMMAND/$TOTAL_COMMANDS) \033[1;32mgit $GIT_COMMAND\033[0;0m"
            git $GIT_COMMAND
            echo
            CURRENT_COMMAND=$(($CURRENT_COMMAND+1))
        done
        echo -e "\033[0;32m-=-=-=-=-=-=-=-=-=-=-=-=-=-\033[0;0m"     
    done
}


function status_mode {
    ## Create status table    
    TOTAL_DIR_ENTRY_LENGTH=35
    TOTAL_BRANCH_ENTRY_LENGTH=10
    TOTAL_STATUS_ENTRY_LENGTH=35
    TOTAL_STAGED_ENTRY_LENGTH=5
    TOTAL_NOT_STAGED_ENTRY_LENGTH=7
    TOTAL_LAST_COMMIT_ENTRY_LENGTH=19

    TOTAL_DIR_ENTRY_SPACES=''
    temp="Repo Name"
    for i in $( seq 0 $(($TOTAL_DIR_ENTRY_LENGTH - ${#temp})) ); do
      TOTAL_DIR_ENTRY_SPACES+=' '
    done    
    TOTAL_BRANCH_ENTRY_SPACES=''
    temp="Branch"
    for i in $( seq 0 $(($TOTAL_BRANCH_ENTRY_LENGTH - ${#temp})) ); do
      TOTAL_BRANCH_ENTRY_SPACES+=' '
    done    
    TOTAL_STATUS_ENTRY_SPACES=''
    temp="Branch"
    for i in $( seq 0 $(($TOTAL_STATUS_ENTRY_LENGTH - ${#temp})) ); do
      TOTAL_STATUS_ENTRY_SPACES+=' '
    done    
    TOTAL_STAGED_ENTRY_SPACES=''
    temp="Staged"
    for i in $( seq 0 $(($TOTAL_STAGED_ENTRY_LENGTH - ${#temp} + 1)) ); do
      TOTAL_STAGED_ENTRY_SPACES+=' '
    done    
    TOTAL_NOT_STAGED_ENTRY_SPACES=''
    temp="Unstaged"
    for i in $( seq 0 $(($TOTAL_NOT_STAGED_ENTRY_LENGTH - ${#temp} + 1)) ); do
      TOTAL_NOT_STAGED_ENTRY_SPACES+=' '
    done
    TOTAL_LAST_COMMIT_ENTRY_SPACES=''
    temp="Not Staged"
    for i in $( seq 0 $(($TOTAL_LAST_COMMIT_ENTRY_LENGTH - ${#temp} + 1)) ); do
      TOTAL_LAST_COMMIT_ENTRY_SPACES+=' '
    done
    temp="$TOTAL_GIT_DIRS"
    DIR_NUM_FORMAT="%${#temp}d"
    REPO_NUMSPACES=''
    for i in $( seq 0 $((3 + 2 * ${#temp} )) ); do
      REPO_NUMSPACES+=' '
    done

    ## table header
    echo
    echo -e "\033[1;34m$REPO_NUMSPACES| Repo Name$TOTAL_DIR_ENTRY_SPACES| Branch$TOTAL_BRANCH_ENTRY_SPACES| Status$TOTAL_STATUS_ENTRY_SPACES| Staged$TOTAL_STAGED_ENTRY_SPACES| Unstaged$TOTAL_NOT_STAGED_ENTRY_SPACES| Last Commit$TOTAL_LAST_COMMIT_ENTRY_SPACES\033[0;0m"
            
    ## For each git repo found, run git status and summarize info into a table format
    GIT_DIR_NUM=0
    on_branch_string="On branch "
    your_branch_is_string="Your branch is "

    for DIR in $DIRS ; do            
        GIT_DIR_NUM=$(($GIT_DIR_NUM+1))   
        REPO_NAME=$(echo $DIR | rev | cut -d/ -f1 | rev)                
        if [[ " ${EXCLUDED_REPOS} " == *" ${REPO_NAME} "* ]]; then            
            continue
        fi

        cd $PROVIDED_REPO_PATH/$DIR

        ## extract info from git status
        STATUS=$(git status)           
        BRANCH=$(echo "$STATUS" | grep 'On branch')        
        UP_TO_DATE=$(echo "$STATUS" | grep 'Your branch is')        
        STAGED=$(echo "$STATUS" | grep 'Changes to be committed')
        NOT_STAGED=$(echo "$STATUS" | grep 'Changes not staged for commit')
        LAST_COMMIT_DATE=$(git log -1 --date=format:'%Y-%m-%d %H:%M:%S'| head -n 4| grep 'Date:')
        LAST_COMMIT_DATE=$(echo $LAST_COMMIT_DATE | cut -c 7-30)
        
        ## repo state. 0 - no changes in tracked files.
        STATUS_STATE=0
        if [ -z "$STAGED" ] ; then
            STAGED_STATUS="None"
        else
            STAGED_STATUS="Exists"
            STATUS_STATE=1
        fi
        if [ -z "$NOT_STAGED" ] ; then
            NOT_STAGED_STATUS="None"
        else
            NOT_STAGED_STATUS="Exists"
            STATUS_STATE=1
        fi

        ## cut strings according to column width
        temp=$((${#DIR} > $TOTAL_DIR_ENTRY_LENGTH  ? $TOTAL_DIR_ENTRY_LENGTH : ${#DIR}))
        DIR_NAME=$(echo $DIR | cut -c 1-$temp)
        temp=$((${#BRANCH} > $TOTAL_BRANCH_ENTRY_LENGTH + ${#on_branch_string} ? ($TOTAL_BRANCH_ENTRY_LENGTH + ${#on_branch_string}) : ${#BRANCH}))
        BRANCH=$(echo $BRANCH | cut -c ${#on_branch_string}-$temp)
        temp=$((${#UP_TO_DATE} > $TOTAL_STATUS_ENTRY_LENGTH + ${#your_branch_is_string} ? ($TOTAL_STATUS_ENTRY_LENGTH + ${#your_branch_is_string}) : ${#UP_TO_DATE}))
        UP_TO_DATE=$(echo $UP_TO_DATE | cut -c ${#your_branch_is_string}-$temp)
        temp=$((${#STAGED_STATUS} > $TOTAL_STAGED_ENTRY_LENGTH  ? $TOTAL_STAGED_ENTRY_LENGTH : ${#STAGED_STATUS}))
        STAGED_STATUS=$(echo $STAGED_STATUS | cut -c 1-$temp)
        temp=$((${#NOT_STAGED_STATUS} > $TOTAL_NOT_STAGED_ENTRY_LENGTH  ? $TOTAL_NOT_STAGED_ENTRY_LENGTH : ${#NOT_STAGED_STATUS}))
        NOT_STAGED_STATUS=$(echo $NOT_STAGED_STATUS | cut -c 1-$temp)
        temp=$((${#LAST_COMMIT_DATE} > $TOTAL_LAST_COMMIT_ENTRY_LENGTH  ? $TOTAL_LAST_COMMIT_ENTRY_LENGTH : ${#LAST_COMMIT_DATE}))
        LAST_COMMIT_DATE=$(echo $LAST_COMMIT_DATE | cut -c 1-$temp)

        ## repo status color. 
        if [[ $UP_TO_DATE == *"up-to-date"* ]] ; then
            if [ $STATUS_STATE == 0 ] ; then
                STATUS_COLOR="\e[42;30m"  # green. up to date with no changes in tracked files.
            else
                STATUS_COLOR="\e[43;30m"  # yellow. up to date but with changes in tracked files.
            fi
        else
            STATUS_COLOR="\e[41;30m"  # red. not up to date.
        fi

        ## calc spaces for table shape
        DIR_SPACES=''
        for i in $( seq 0 $(($TOTAL_DIR_ENTRY_LENGTH - ${#DIR_NAME} -1))) }; do
            DIR_SPACES+=' '
        done
        BRANCH_SPACES=''
        for i in $( seq 0 $(($TOTAL_BRANCH_ENTRY_LENGTH - ${#BRANCH}))) }; do
            BRANCH_SPACES+=' '
        done
        STATUS_SPACES=''
        for i in $( seq 0 $(($TOTAL_STATUS_ENTRY_LENGTH - ${#UP_TO_DATE}))) }; do
            STATUS_SPACES+=' '
        done
        STAGED_SPACES=''
        for i in $( seq 0 $(($TOTAL_STAGED_ENTRY_LENGTH - ${#STAGED_STATUS}))) }; do
            STAGED_SPACES+=' '
        done
        NOT_STAGED_SPACES=''
        for i in $( seq 0 $(($TOTAL_NOT_STAGED_ENTRY_LENGTH - ${#NOT_STAGED_STATUS}))) }; do
            NOT_STAGED_SPACES+=' '
        done

        ## dispaly repo status line as a row in the table
        echo -e "$STATUS_COLOR($(printf "$DIR_NUM_FORMAT" $GIT_DIR_NUM)/$TOTAL_GIT_DIRS) | $DIR_NAME$DIR_SPACES|$BRANCH$BRANCH_SPACES|$UP_TO_DATE$STATUS_SPACES| $STAGED_STATUS$STAGED_SPACES| $NOT_STAGED_STATUS$NOT_STAGED_SPACES| $LAST_COMMIT_DATE\e[49;39m"                      
    done
}

## print help if no args provided
if [ $# == 0 ]; then
    usage
fi

## parse input arguments
GIT_COMMANDS=()
EXCLUDED_REPOS=()
COMMAND_MODE=false
STATUS_MODE=false
while [[ $# -gt 0 ]] ; do
    key="$1"

    case $key in
        -p|--path)
            PROVIDED_REPO_PATH="$2"
            shift # past argument
            shift # past value
        ;;
        -h|--help)
            usage
            exit 1
        ;;
        -e|--exclude)
            EXCLUDED_REPOS+=("$2")
            shift # past argument
            shift # past value
        ;;
        -c|--command)
            COMMAND_MODE=true
            shift # past argument
        ;;
        -s|--status)
            STATUS_MODE=true
            shift # past argument
        ;;
        *)    # unknown option
            case $1 in
                s)
                    GIT_COMMANDS+=("status")
                ;;
                p)
                    GIT_COMMANDS+=("pull")
                ;;
                f)
                    GIT_COMMANDS+=("fetch")
                ;;
                scp)
                    GIT_COMMANDS+=("stash")
                    GIT_COMMANDS+=("checkout master")
                    GIT_COMMANDS+=("pull")
                ;;
                rcp)
                    GIT_COMMANDS+=("reset --hard")
                    GIT_COMMANDS+=("checkout master")
                    GIT_COMMANDS+=("pull")
                ;;
                *)
                    GIT_COMMANDS+=("$1") # save it in an array for later        
                ;;
            esac
            shift # past argument
        ;;
    esac
done

## set path with provided path or from an external GITREPO variable if not provided
if [ -z "$PROVIDED_REPO_PATH" ] ; then
    PROVIDED_REPO_PATH=$GITREPOPATH
fi


if [ "$PROVIDED_REPO_PATH" != "" ] ; then
   echo -e "\033[1;33mSearching repositories in: $PROVIDED_REPO_PATH\033[0;0m"  
   
   ## list all dirs in path
    DIRS=$(find $PROVIDED_REPO_PATH -name .git -type d -prune -printf "%P\n"| grep -v build | grep -Fxv .git| rev | cut -d/ -f2- | cut -d: -f2-| rev | sort)
   
   if [ ! -z "$DIRS" ] ; then   

        ## calculate # of dirs that are git repos
        TOTAL_GIT_DIRS=0
        for DIR in $DIRS ; do
            TOTAL_GIT_DIRS=$(($TOTAL_GIT_DIRS+1))
        done
        echo -e "\033[1;33mFound $TOTAL_GIT_DIRS repositories.\033[0;0m"
        
        if [ "$COMMAND_MODE" = true ]; then
            command_mode
            echo
        fi
        if [ "$STATUS_MODE" = true ]; then
            status_mode
            echo
        fi
   else
      echo "Git repositories not found."
   fi
fi

