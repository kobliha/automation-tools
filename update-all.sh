##
# Fetches the latest state of available repositories from Git
#
# You need to start this script in directory with all repositories ckecked-out
# See https://github.com/yast/yast-meta for more details
##

STARTDIR=`pwd`;

for D in `ls`; do
  echo && echo
  echo "Workin in repository: $D"
  cd $D && git fetch && git stash
  # Sometimes there is no master so it's not rebased either
  git checkout master && git rebase origin/master
  cd ${STARTDIR}
  # Let's be nice to git server
  sleep 3
done
