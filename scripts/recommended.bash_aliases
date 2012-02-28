# I use this on most of the systems I manage, it may help you as well.
# To use, just place in your home directory and call ". .bash_aliases" from your .bashrc file.

# OS Stuff
alias df='df -h'
alias diff='diff -Nur'
alias dir='ls --color=auto --format=vertical'
alias du='du -h'
alias ll='ls --color -lh'
alias ls='ls --color=auto'
alias pa='ps -efwwwww | grep -v grep | grep $1'
alias vi='vim'
export EDITOR='vim'

# MySQL Stuff
# Note: Replace mysql password with your password
alias mysql='mysql -uroot -pmysql'
alias mysqladmin='mysqladmin -uroot -pmysql'
alias mysqlcheck='mysqlcheck -uroot -pmysql --auto-repair'
alias mysqldump='mysqldump -uroot -pmysql'
alias mysqlreport='mysqlreport --user=root --password=mysql'
alias mysqlshow='mysqldump -uroot -pmysql'
alias mytop='mytop -uroot -pmysql'

# LogZilla stuff
# Note: Replace mysql password with your password
export lz='/var/www/logzilla'
alias mysqltuner='$lz/scripts/tools/mysqltuner.pl --user root --pass mysql'
alias summary='$lz/scripts/tools/summary'
alias lzupdate='(printf "\n\n\tIf conflicts occur during update, check the diff using df (diff full)\nIf it is just a path differenc
e, then select mc (mine conflict) to keep your version.\n" && cd $lz && svn update)'

# Sphinx shortcuts
alias myspx='mysql -h0 -P9306'
alias spx_full='(cd $lz/sphinx && ./indexer.sh full)'
alias spx_delta='(cd $lz/sphinx && ./indexer.sh delta)'
alias spx_stop='(cd $lz/sphinx && bin/searchd --stop)'
alias spx_start='(cd $lz/sphinx && bin/searchd)'
