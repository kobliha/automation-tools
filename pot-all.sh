##
# Generates pot files in all subdirectories (repositorires)
# Run `pot-all.sh 11` to generate the latest pot files for
# SLE 11 (automatically takes the highest available branch)
#
# You need to start this script in directory with all repositories ckecked-out
# See https://github.com/yast/yast-meta for more details
##

CODESTREAM=$1

if [ "${CODESTREAM}" == "" ]; then
  echo "Run $0 codestream-number (e.g., 10, 11 or 12...)"
  exit 1
elif [[ ${CODESTREAM} =~ ^1[0-9]$ ]]; then
  echo "Using codestream ${CODESTREAM}"
else
  echo "Not a valid codestream '${CODESTREAM}', use 10, 11 or 12..."
  exit 1
fi

STARTDIR=`pwd`;

# Temporary branch is created and then removed later
TMP_BRANCH="generate-pot-files_branch-to-be-removed"
# At the end, script checks out this branch
FINISHES_IN_BRANCH="master"
# or this branch, if the first one fails
OR_IN_BRANCH="master_old"

for D in `ls`; do
  cd ${STARTDIR}
  echo && echo
  cd ${D} || continue
  echo "Working in repository ${D}"

  # Finds the latest branch (the highest branch Nr.) in repository
  LATEST_BRANCH=`git branch -a | grep "remotes/origin/.*-${CODESTREAM}\(-\(GA\|SP[1-9]\)\)\?$" | sort | tail -n 1 | sed 's/^.*\///'`
  echo "Last branch: ${LATEST_BRANCH}"
  if [ "${LATEST_BRANCH}" == "" ]; then
    echo "No codestream ${CODESTREAM} branch"
    continue
  fi

  git branch -a | grep ${TMP_BRANCH} && git branch -D ${TMP_BRANCH}
  git branch ${TMP_BRANCH} origin/${LATEST_BRANCH}
  git checkout ${TMP_BRANCH}

  # Texts can't be generated directly from control files
  # they have to be linked as *.glade first
  if [[ $F =~ ^(skelcd-control-.*|installation|installation-control|update|dirinstall)$ ]]; then
    cd control
    rm -rf *.glade
    for F in `ls *.xml | sed 's/.xml//'`; do echo linking ${F}; ln -s $F.xml ${F}.glade; done
    rm -rf *.glade
  # Ignore these repositories
  elif [[ $F =~ ^(devtools|doc|testsuite)$ ]]; then
    continue
  fi

  rm -rf *.pot
  y2tool y2makepot && ls *.pot

  git stash
  git checkout ${FINISHES_IN_BRANCH} || git checkout ${OR_IN_BRANCH}
  git branch -a | grep ${TMP_BRANCH} && git branch -D ${TMP_BRANCH}
done

cd ${STARTDIR}
