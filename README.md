# Multi Git Tool

## What is it?

The Multi Git Tool is a simple tool to manage multiple git repositories.

The tool operates on all subdierectories of a provided path or from the env variable GITREPOPATH.

![Multi Git Tool Demo](multi_git_tool.gif)

## Install

```console
sudo -E wget https://raw.githubusercontent.com/borisindelman/multi_git_tool/master/multi_git_tool.sh -P /usr/local/bin && sudo chmod 755 /usr/local/bin/multi_git_tool.sh
```

## Usage

```console
multi_git_tool.sh [-p] <path/to/repo> [-s] [-i] <repo_include_list> [-e] <repo_exclude_list> [-f] <path/to/repo_list.txt> [-y] [-c] <command1> <command2> ...

```console
*  -p, --path          path to repo. if not provided will use GITREPOPATH variable.
*  -s, --status        show a status summary in a table format.
*  -i, --include       list of repos to include.
*  -e, --exclude       list of repo names to exclude.
*  -f, --file          path to a file that contains repo names to include.
*  -c, --command       set of git commands to run on all detected repos.
*  -y, --yes           run commands without asking for user's approval.

command shortcuts:
* s = status
* p = pull
* f = fetch
* scp = status, checkout master, pull
* rcp = reset --hard, ceckout master, pull

## Examples

* Status table for all repos

    ```console
    multi_git_tool -p /path/to/repo -s
    ```

* `git status` for each repo

    ```console
    multi_git_tool -p /path/to/repo -c status
    ```

* `git pull` for each repo

    ```console
    multi_git_tool -p /path/to/repo -c pull
    ```

* `git checkout msater` and then `git pull` and them show status table

    ```console
    multi_git_tool -p /path/to/repo -s -c 'checkout master' pull
    ```

* `git reset --hard` & `git checkout master` & `git pull` & show status table

    ```console
    multi_git_tool -p /path/to/repo -s -c rcp
    ```

* `git pull` for each repo except repo_b

    ```console
    multi_git_tool -p /path/to/repo -e repo_b -c pull
    ```

* `git pull` for each repo except repo_b and repo_c

    ```console
    multi_git_tool -p /path/to/repo -e 'repo_b repo_c' -c pull
    ```

* `git pull` for only repos repo_b and repo_c

    ```console
    multi_git_tool -p /path/to/repo -i 'repo_b repo_c' -c pull
    ```

* `git pull` for a repo list provided in a file

    ```console
    multi_git_tool -p /path/to/repo -f /path/to/repo_list.txt -c pull
    ```
