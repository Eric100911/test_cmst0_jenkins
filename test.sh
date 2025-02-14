#Run your code

# A simple script to test the collatz conjecture code from a GitHub PR

# The temporary value for the repo URL and PR ID.
REPO_URL="https://github.com/Eric100911/collatz.git"
PR_ID="1"

# Extract the PR number from environment variable.
# We do have PULL_REQUEST as the ID of the PR, also REPOSITORY as the user/repo

if [ -n "${PULL_REQUEST}" ] ; then
  PR_ID=${PULL_REQUEST}
fi

if [ -n "${REPOSITORY}" ] ; then
  REPO_URL="https://github.com/${REPOSITORY}.git"
else 
  echo "REPOSITORY is not set. Extracting from the PR URL."
  REPOSITORY=$(echo ${REPO_URL} | sed -r -e 's,^.*github.com\/(.*)\.git$,\1,')
fi

echo "Testing PR #${PR_ID} from ${REPO_URL}"
echo "REPOSITORY=${REPOSITORY}"

# Extract repo name from link
REPO_NAME=$(echo ${REPOSITORY} | sed -r -e 's,^.*\/([^\/]+)$,\1,')
echo "Repo name: ${REPO_NAME}"

# Clone the repo
git clone ${REPO_URL}

# Marker for test result and also git clone.
run_result=0

# Prepare the python environment for grade.py, not much here.


# Check if the repo was cloned
if [ ! -d ${REPO_NAME} ] ; then
  echo "Failed to clone ${REPO_URL}" >> err.txt
else
  echo "Successfully cloned ${REPO_URL}"
  cd ${REPO_NAME}

  # Switch to the PR branch
  git fetch origin "pull/${PR_ID}/head:pr-${PR_ID}"
  git checkout "pr-${PR_ID}"  
  python3 grade.py > tmp_result.txt

  # Return to the workspace
  cd ..
fi


#Create a file with comment to be posrted on GH PR
set +x
echo "+1" > comment.txt
echo "Job finished. Compilete build log is available at ${BUILD_URL}/console" >> comment.txt

# If error file exists, add it to the comment
if [ -e ${REPO_NAME}/err.txt ] ; then
  echo "Error:" >> comment.txt
  cat ${REPO_NAME}/err.txt >> comment.txt
fi
if [ -e ${REPO_NAME}/tmp_result.txt ] ; then
  # If successfully created the ${REPO_NAME}/tmp_result.txt, we can add it to the comment
  echo "Test result for PR #${PR_ID}:" >> comment.txt
  cat ${REPO_NAME}/tmp_result.txt >> comment.txt
fi

# If changelog exists, add it to the comment
if [ -e ${REPO_NAME}/changelog.txt ] ; then
  echo "Changelog:" >> comment.txt
  cat ${REPO_NAME}/changelog.txt >> comment.txt
fi

if [ -e ${WORKSPACE}/comment.txt ] ; then
  COMMENT=$(cat comment.txt | python3 -c 'import sys,zlib,base64;msg=sys.stdin.read().strip();print(base64.encodebytes(zlib.compress(msg.encode())).decode("ascii", "ignore"))' | sed ':a;N;$!ba;s/\n/@N@/g')
  echo "COMMENT=b64:${COMMENT}" >> post-gh-comment
fi
