#!/bin/sh

git filter-branch --env-filter '

OLD_EMAIL="root@sup1.mnt-tech.fr"
CORRECT_NAME="nierdz"
CORRECT_EMAIL="kevin.met@mnt-tech.fr"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -f -- --branches --tags
