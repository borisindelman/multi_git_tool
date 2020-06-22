#!/bin/bash

PROGRAMNAME=$0

SCRIPT_PATH="${0%/*}"
LOG_FILE="$SCRIPT_PATH/multi_git_tool.log"
printf -v DATE_TIME '%(%Y-%m-%d %H:%M:%S)T' -1 
echo "$DATE_TIME - ran $PROGRAMNAME $*" >> "$LOG_FILE"


function usage {    
    echo "multi_git_tool is a simple git tool to manage multiple repositories."
    echo "The tool operates on all subdierectories to a provided path or from the env variable GITREPOPATH."
    echo
    echo "Usage: multi_git_tool.sh [-p] <path/to/repo> [-s] [-i] <repo_include_list> [-e] <repo_exclude_list> [-y] [-c] <command1> <command2> ..."
    echo "  -p, --path          path to repo. if not provided will use GITREPOPATH variable"
    echo "  -s, --status        show a status summary in a table format"
    echo "  -i, --include       list of repos to include."
    echo "  -e, --exclude       list of repo names to exclude."
    echo "  -f, --file          path to a file that contains repo names to include."
    echo "  -c, --command       set of git commands to run on all detected repos."
    echo "  -y, --yes           run commands without asking for user's approval."
    echo
    echo "commands shortcuts and combos:"
    echo "  s = status"
    echo "  p = pull"
    echo "  f = fetch"
    echo "  scp = status, checkout master, pull"
    echo "  rcp = reset --hard, ceckout master, pull"
    exit 1
}


function command_mode {
    TOTAL_COMMANDS=${#GIT_COMMANDS[@]}

    if [ "$TOTAL_COMMANDS" == 0 ]; then
        echo "No commands provided."
        exit 1
    fi
    
    echo -e "\033[1;33mRunning $TOTAL_COMMANDS commands:\033[0;0m"          
    for GIT_COMMAND in "${GIT_COMMANDS[@]}"; do # access each element of array
      echo -e "\033[3;33m   git $GIT_COMMAND\033[0;0m"
    done      
    echo 

    if [ "$SKIP_USR_APPROVAL" == false ]; then
        read -p "Press any key to continue"
    fi

    ## For each git repo found, run all commands
    GIT_DIR_NUM=0
    for DIR in "${DIRS[@]}" ; do
        GIT_DIR_NUM=$(($GIT_DIR_NUM+1))
        REPO_NAME=$(echo $DIR | rev | cut -d/ -f1 | rev)
        
        if [ $DIR == ".git" ]; then
            cd $PROVIDED_REPO_PATH
            DIR=$(echo $PROVIDED_REPO_PATH | rev | cut -d/ -f1 | rev)
        else
            cd $PROVIDED_REPO_PATH/$DIR
        fi

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
    TOTAL_BRANCH_ENTRY_LENGTH=30
    TOTAL_STATUS_ENTRY_LENGTH=35
    TOTAL_STAGED_ENTRY_LENGTH=5
    TOTAL_NOT_STAGED_ENTRY_LENGTH=7
    TOTAL_LAST_FETCH_ENTRY_LENGTH=14 

    temp="Repo Name"
    TOTAL_DIR_ENTRY_SPACES=$(printf " %.0s" $( seq $(($TOTAL_DIR_ENTRY_LENGTH - ${#temp} + 2)) ))
    temp="Branch"
    TOTAL_BRANCH_ENTRY_SPACES=$(printf " %.0s" $( seq $(($TOTAL_BRANCH_ENTRY_LENGTH - ${#temp})) ))
    temp="Status"
    TOTAL_STATUS_ENTRY_SPACES=$(printf " %.0s" $( seq $(($TOTAL_STATUS_ENTRY_LENGTH - ${#temp})) ))
    temp="Staged"
    TOTAL_STAGED_ENTRY_SPACES=$(printf " %.0s" $( seq $(($TOTAL_STAGED_ENTRY_LENGTH - ${#temp} + 1)) ))
    temp="Unstaged"
    TOTAL_NOT_STAGED_ENTRY_SPACES=$(printf " %.0s" $( seq $(($TOTAL_NOT_STAGED_ENTRY_LENGTH - ${#temp} + 1)) ))
    temp="Last Fetch"
    TOTAL_LAST_FETCH_ENTRY_SPACES=$(printf " %.0s" $( seq $(($TOTAL_LAST_FETCH_ENTRY_LENGTH - ${#temp} + 1)) ))
    temp="$TOTAL_GIT_DIRS"
    DIR_NUM_FORMAT="%${#temp}d"
    REPO_NUMSPACES=$(printf " %.0s" $( seq 0 $((${#temp} )) ))

    ## table header
    echo
    # echo -e "\033[1;34m$REPO_NUMSPACES| Repo Name$TOTAL_DIR_ENTRY_SPACES| Branch$TOTAL_BRANCH_ENTRY_SPACES| Status$TOTAL_STATUS_ENTRY_SPACES| Staged$TOTAL_STAGED_ENTRY_SPACES| Unstaged$TOTAL_NOT_STAGED_ENTRY_SPACES| Last Commit$TOTAL_LAST_COMMIT_ENTRY_SPACES\033[0;0m"
    echo -e "\033[1;34m$REPO_NUMSPACES| Repo Name$TOTAL_DIR_ENTRY_SPACES| Branch$TOTAL_BRANCH_ENTRY_SPACES| Status$TOTAL_STATUS_ENTRY_SPACES| Staged$TOTAL_STAGED_ENTRY_SPACES| Unstaged$TOTAL_NOT_STAGED_ENTRY_SPACES| Last Fetch$TOTAL_LAST_FETCH_ENTRY_SPACES\033[0;0m"

    ## For each git repo found, run git status and summarize info into a table format
    GIT_DIR_NUM=0
    on_branch_string="On branch "
    your_branch_is_string="Your branch is "

    for DIR in "${DIRS[@]}" ; do            
        GIT_DIR_NUM=$(($GIT_DIR_NUM+1))   
        REPO_NAME=$(echo $DIR | rev | cut -d/ -f1 | rev)                

        if [ $DIR == ".git" ]; then
            cd $PROVIDED_REPO_PATH
            DIR=$(echo $PROVIDED_REPO_PATH | rev | cut -d/ -f1 | rev)
        else
            cd $PROVIDED_REPO_PATH/$DIR
        fi

        ## extract info from git status
        STATUS=$(git status)           
        BRANCH=$(echo "$STATUS" | grep 'On branch')        
        UP_TO_DATE=$(echo "$STATUS" | grep 'Your branch is') 
        NEW_REPO=false      
        if [ -z "$UP_TO_DATE" ]; then
            UP_TO_DATE=$(echo "$STATUS" | grep 'Initial commit') 
            UP_TO_DATE=" $UP_TO_DATE"
            NEW_REPO=true
        fi
        STAGED=$(echo "$STATUS" | grep 'Changes to be committed')
        NOT_STAGED=$(echo "$STATUS" | grep 'Changes not staged for commit')
        LAST_FETCH_DATE=''
        if [ "$NEW_REPO" = false ]; then
            LAST_FETCH_DATE=$(date +%Y%m%d-%H:%M -r .git/FETCH_HEAD)
        fi

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
        temp=$((${#BRANCH} > $TOTAL_BRANCH_ENTRY_LENGTH + ${#on_branch_string} -1 ? ($TOTAL_BRANCH_ENTRY_LENGTH + ${#on_branch_string}) - 1 : ${#BRANCH}))
        BRANCH=$(echo $BRANCH | cut -c ${#on_branch_string}-$temp)
        if [ "$NEW_REPO" = false ]; then
            temp=$((${#UP_TO_DATE} > $TOTAL_STATUS_ENTRY_LENGTH + ${#your_branch_is_string} -1 ? ($TOTAL_STATUS_ENTRY_LENGTH + ${#your_branch_is_string}) - 1 : ${#UP_TO_DATE}))        
            UP_TO_DATE=$(echo $UP_TO_DATE | cut -c ${#your_branch_is_string}-$temp)
        fi
        temp=$((${#STAGED_STATUS} > $TOTAL_STAGED_ENTRY_LENGTH  ? $TOTAL_STAGED_ENTRY_LENGTH : ${#STAGED_STATUS}))
        STAGED_STATUS=$(echo $STAGED_STATUS | cut -c 1-$temp)
        temp=$((${#NOT_STAGED_STATUS} > $TOTAL_NOT_STAGED_ENTRY_LENGTH  ? $TOTAL_NOT_STAGED_ENTRY_LENGTH : ${#NOT_STAGED_STATUS}))
        NOT_STAGED_STATUS=$(echo $NOT_STAGED_STATUS | cut -c 1-$temp)
        if [ "$NEW_REPO" = false ]; then
            temp=$((${#LAST_FETCH_DATE} > $TOTAL_LAST_FETCH_ENTRY_LENGTH  ? $TOTAL_LAST_FETCH_ENTRY_LENGTH : ${#LAST_FETCH_DATE}))
            LAST_FETCH_DATE=$(echo $LAST_FETCH_DATE | cut -c 1-$temp)
        fi

        ## repo status color. 
        if [[ $UP_TO_DATE == *"up-to-date"* ]] ; then
            if [ $STATUS_STATE == 0 ] ; then
                STATUS_COLOR="\e[2;42;30m"  # green. up to date with no changes in tracked files.
            else
                STATUS_COLOR="\e[2;43;30m"  # yellow. up to date but with changes in tracked files.
            fi
        else
            STATUS_COLOR="\e[2;41;30m"  # red. not up to date.
        fi

        ## calc spaces for table shape
        DIR_SPACES=$(printf " %.0s" $(seq $(($TOTAL_DIR_ENTRY_LENGTH - ${#DIR_NAME} + 2))))
        BRANCH_SPACES=$(printf " %.0s" $(seq $(($TOTAL_BRANCH_ENTRY_LENGTH - ${#BRANCH} + 1))))
        STATUS_SPACES=$(printf " %.0s" $(seq $(($TOTAL_STATUS_ENTRY_LENGTH - ${#UP_TO_DATE} + 1))))
        STAGED_SPACES=$(printf " %.0s" $(seq $(($TOTAL_STAGED_ENTRY_LENGTH - ${#STAGED_STATUS} + 2))))
        NOT_STAGED_SPACES=$(printf " %.0s" $(seq $(($TOTAL_NOT_STAGED_ENTRY_LENGTH - ${#NOT_STAGED_STATUS} + 2))))       
        LAST_FETCH_SPACES=$(printf " %.0s" $(seq $(($TOTAL_LAST_FETCH_ENTRY_LENGTH - ${#LAST_FETCH_DATE} + 2))))       

        ## dispaly repo status line as a row in the table
        # echo -e "$STATUS_COLOR($(printf "$DIR_NUM_FORMAT" $GIT_DIR_NUM)/$TOTAL_GIT_DIRS) | $DIR_NAME$DIR_SPACES|$BRANCH$BRANCH_SPACES|$UP_TO_DATE$STATUS_SPACES| $STAGED_STATUS$STAGED_SPACES| $NOT_STAGED_STATUS$NOT_STAGED_SPACES| $LAST_COMMIT_DATE$LAST_COMMIT_SPACES\e[49;39m"                      
        echo -e "$STATUS_COLOR$(printf "$DIR_NUM_FORMAT" $GIT_DIR_NUM) | $DIR_NAME$DIR_SPACES|$BRANCH$BRANCH_SPACES|$UP_TO_DATE$STATUS_SPACES| $STAGED_STATUS$STAGED_SPACES| $NOT_STAGED_STATUS$NOT_STAGED_SPACES| $LAST_FETCH_DATE$LAST_FETCH_SPACES\e[49;39m"                      
    done
}

## print help if no args provided
if [ $# == 0 ]; then
    usage
fi

## parse input arguments
GIT_COMMANDS=()
COMMAND_MODE=false
STATUS_MODE=false
EXCLUDED_REPOS=()
EXCLUDE_MODE=false
INCLUDED_REPOS=()
INCLUDE_MODE=false
FILE_MODE=false
SKIP_USR_APPROVAL=false
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
            EXCLUDE_MODE=true
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
        -i|--include)
            INCLUDE_MODE=true
            INCLUDED_REPOS+=("$2")
            shift # past argument
            shift # past value
        ;;
        -f|--file)
            FILE_MODE=true
            FILE_PATH=("$2")
            shift # past argument
            shift # past value
        ;;
        -y|--yes)
            SKIP_USR_APPROVAL=true
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
    
    # make sure flags are used correctly
    if [ "$INCLUDE_MODE" == true ] && [ "$EXCLUDE_MODE" == true ]; then
        
        echo "Error! supplied both include and exclude flags. Please choose only one of them."
        exit 1    
    elif [ "$INCLUDE_MODE" == true ] && [ "$FILE_MODE" == true ]; then
        
        echo "Error! supplied both include and file flags. Please choose only one of them."
        exit 1
    elif [ "$EXCLUDE_MODE" == true ] && [ "$FILE_MODE" == true ]; then
        echo "Error! supplied both exclude and file flags. Please choose only one of them."
        exit 1
    fi

    # read from file if -f flag provided
    if [ "$FILE_MODE" == true ]; then
        end_of_file=0
        while [[ $end_of_file == 0 ]]; do
            read -r line
            end_of_file=$?
            line=($(echo "$line" | tr ' ' '\n'))
            for name in "${line[@]}"; do
                INCLUDED_REPOS+=("$name")
            done
        done < "$FILE_PATH"
        INCLUDE_MODE=true
    fi

    # print exclude/include repos
    if [ "$INCLUDE_MODE" == true ]; then
        echo -e "\033[1;33mIncluding: \033[0;3;33m${INCLUDED_REPOS[@]}\033[0;0m"
    elif [ "$EXCLUDE_MODE" == true ]; then
        echo -e "\033[1;33mExcluding: \033[0;3;33m${EXCLUDED_REPOS[@]}\033[0;0m"
    fi
    ## list all dirs in path
    # ALL_DIRS=$(find $PROVIDED_REPO_PATH -name .git -type d -prune -printf "%P\n"| grep -v build | grep -Fxv .git| rev | cut -d/ -f2- | cut -d: -f2-| rev | sort)
    ALL_DIRS=$(find $PROVIDED_REPO_PATH -name .git -type d -prune -printf "%P\n"| grep -v build | rev | cut -d/ -f2- | cut -d: -f2-| rev | sort)

    DIRS=()
    if [ ! -z "$ALL_DIRS" ] ; then   

        for DIR in $ALL_DIRS ; do      
            REPO_NAME=$(echo $DIR | rev | cut -d/ -f1 | rev) 
            if [ "$EXCLUDE_MODE" == true ]; then
                if [[ ! " ${EXCLUDED_REPOS[@]} " == *" ${REPO_NAME} "* ]]; then     
                    DIRS+=("$DIR")                
                fi
            elif [ "$INCLUDE_MODE" == true ]; then
                if [[ " ${INCLUDED_REPOS[@]} " == *" ${REPO_NAME} "* ]]; then                
                    DIRS+=("$DIR")
                fi
            else
                DIRS+=("$DIR")
            fi
        done      

        TOTAL_GIT_DIRS=${#DIRS[*]}
        TOTAL_ALL_GIT_DIRS=$(echo "$ALL_DIRS" | wc -w)
        if [ "$EXCLUDE_MODE" == true ] ||  [ "$INCLUDE_MODE" == true ]; then
           echo -e "\033[1;33mFound $TOTAL_GIT_DIRS repositories out of $TOTAL_ALL_GIT_DIRS.\033[0;0m"
        else
           echo -e "\033[1;33mFound $TOTAL_GIT_DIRS repositories.\033[0;0m"
        fi
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

