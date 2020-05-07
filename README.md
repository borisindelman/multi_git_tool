# Multi Git Tool

## What is it?

The Multi Git Tool is a simple tool to manage multiple git repositories.

The tool operates on all subdierectories of a provided path or from the env variable GITREPOPATH.

![Multi Git Tool Demo](multi_git_tool.gif)


## Usage
```bash
Usage: multi_git_tool.sh [-p] <path/to/repo> [-s] [-e] <repo_exclude_list> [-c] <command1> <command2> ...
```
* -p|--path   : provide path to repo, else Will use GITREPOPATH variable
* -e|--exclude: list of repo names to exclude
* -s|--status : status mode
* -c|--command: commands mode

command shortcuts:
* s = status
* p = pull
* f = fetch
* scp = status, checkout master, pull
* rcp = reset --hard, ceckout master, pull

## Examples

* Status table for all repos
    ```bash
    multi_git_tool -p /path/to/repo -s
    ```
* `git status` for each repo
    ```bash
    multi_git_tool -p /path/to/repo -c status
    ```
* `git pull` for each repo
    ```bash
    multi_git_tool -p /path/to/repo -c pull 
    ```
* `git checkout msater` and then `git pull` and them show status table
    ```bash
    multi_git_tool -p /path/to/repo -s -c 'checkout master' pull
    ```
* `git reset --hard` & `git checkout master` & `git pull` & show status table
    ```bash
    multi_git_tool -p /path/to/repo -s -c rcp
    ```
* `git pull` for each repo except repo_b
    ```bash
    multi_git_tool -p /path/to/repo -e repo_b -c pull
    ```
* `git pull` for each repo except repo_b and repo_c
    ```bash
    multi_git_tool -p /path/to/repo -e 'repo_b repo_c' -c pull
    ```