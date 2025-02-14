# CI/CD Pipeline Config for CMS-Jenkins

## Brief

This is a note for the whole process of creating a CI/CD pipeline using CMS-Jenkins. This is originally intened for performing the test on tier-0 machine `vocms047` .

The pipeline is supported by `cmsbot`, which runs on `cmsbuild` machines and can access the `vocms047` through SSH public key authentication to create a workspace directory and execute the script that is  configured on CMS-Jenkins web page (see example next section) . 

Upon pull request to `user/repo`, to initiate the test, one need to type any comment with one line "@cmsbot please test", which triggers the `cmsbot` to run the test. The contents in bash variable `COMMENT` will be tranferred back to the GitHub pull request as a separate comment.

## Configuring

### Register the User Repository on `cms-sw/cmsbot `

1. Fork the repo `cms-sw/cmsbot `, create directory `repos/USER_NAME/REPO_NAME`.

2. Create a config file `repo_config.py` in the directory. You may configure as below (see also: other examples in `cms-sw/cmsbot/repos`) 

    ```python
    from cms_static import get_jenkins
    from os.path import basename, dirname, abspath
    
    # GH read/write token: Use default ~/.github-token-cmsbot
    GH_TOKEN = "~/.github-token-cmsbot"
    # GH readonly token: Use default ~/.github-token-readonly
    GH_TOKEN_READONLY = "~/.github-token-readonly"
    CONFIG_DIR = dirname(abspath(__file__))
    # GH bot user: Use default cmsbot
    CMSBUILD_USER = "cmsbot"
    GH_REPO_ORGANIZATION = basename(dirname(CONFIG_DIR))
    GH_REPO_FULLNAME = "dmwm/T0"
    CREATE_EXTERNAL_ISSUE = False
    # cmsbot will not have admin. The webhook is added by repo admin.
    ADD_WEB_HOOK = False
    # Token is to be set up by repo admin.
    GITHUB_WEBHOOK_TOKEN = "U2FsdGVkX1/yGRI4T5Xuk69SIVHNLg1fgE1+BU1eiRemkuUdkmqIZD0ICUVaEuO2"
    REQUEST_PROCESSOR = "simple-cms-bot"
    TRIGGER_PR_TESTS = []
    VALID_WEB_HOOKS = ["issue_comment"]
    WEBHOOK_PAYLOAD = True
    # Jenkins CI server: User default http://cms-jenkins.cern.ch:8080/cms-jenkins
    JENKINS_SERVER = get_jenkins("cms-jenkins")
    
    ```

### Create GitHub Webhook

1. In the user repository web page, check "Settings - Code and automation - Webhooks - Add Webhook"
2. Set up such configurations: 
    - Disable SSL Verificaton (as github does not recognize cmssdt.cern.ch certificate)
    - Payload URL: https://cmssdt.cern.ch/SDT/cgi-bin/github_webhook
    - Content type: application/json
    - Secret: any password of your choice
    - Disable SSL Verification
    - Let me select individual events: Select
        - Issues, Issue comment, Pull request 
        - Pushes (for push based events)
    - Once you have created the webhook then please encrypt your secret by running `curl -d 'TOKEN=your-secret' https://cmssdt.cern.ch/SDT/cgi-bin/encrypt_github_token` and add `GITHUB_WEBHOOK_TOKEN=encrypted-token` in the `repos/<user>/<repo>/repo_config.py` file.

> This section is mostly borrowed from `cms-sw/cmsbot/repos/README.md ` .
>
> In the case with T0 CI/CD, we will not add `cmsbot` as `admin`. 

### Set Up `shell` Script for Testing

The test script is set up in the web page of the Jenkins job and has a general framework as below (see also examples in `cms-sw/cmsbot/repos/`):

```bash
#Run your code

# A simple script to test the collatz conjecture code from a GitHub PR

# Extract the PR number from environment variable.
# We do have PULL_REQUEST as the ID of the PR, also REPOSITORY as the user/repo

if [ -n "${PULL_REQUEST}" ] ; then
  PR_ID=${PULL_REQUEST}
else 
  exit -1
fi

if [ -n "${REPOSITORY}" ] ; then
  REPO_URL="https://github.com/${REPOSITORY}.git"
else 
  echo "REPOSITORY is not set. Extracting from the PR URL."
  REPOSITORY=$(echo ${REPO_URL} | sed -r -e 's,^.*github.com\/(.*)\.git$,\1,')
fi

# Extract repo name from link
REPO_NAME=$(echo ${REPOSITORY} | sed -r -e 's,^.*\/([^\/]+)$,\1,')
echo "Repo name: ${REPO_NAME}"

# Clone the repo
git clone ${REPO_URL}
# Prepare necessary env variables

# Check if the repo was cloned
if [ ! -d ${REPO_NAME} ] ; then
  echo "Failed to clone ${REPO_URL}" >> err.txt
else
  echo "Successfully cloned ${REPO_URL}"
  cd ${REPO_NAME}
  # Switch to the PR branch
  git fetch origin "pull/${PR_ID}/head:pr-${PR_ID}"
  git checkout "pr-${PR_ID}"  
  # >>> Conduct your test for the PR here. <<<

  # >>>       End of test for the PR       <<<
  # Return to the workspace
  cd ..
fi

#Create a file with comment to be posted on GH PR
set +x
echo "+1" > comment.txt
echo "Job finished. Compilete build log is available at ${BUILD_URL}/console" >> comment.txt

if [ -e ${WORKSPACE}/comment.txt ] ; then
  COMMENT=$(cat comment.txt | python3 -c 'import sys,zlib,base64;msg=sys.stdin.read().strip();print(base64.encodebytes(zlib.compress(msg.encode())).decode("ascii", "ignore"))' | sed ':a;N;$!ba;s/\n/@N@/g')
  echo "COMMENT=b64:${COMMENT}" >> post-gh-comment
fi

```

A more elegant way may be including the script for testing as part of the repo to be tested. With this, one can simply execute the dedicated test script in the area indicated above and avoid the trouble of frequently modifying the script in Jenkins web page.





## REF from `cms-sw/cmsbot/repos/README.md `: Adding your repository so that CMS CI system can process webhooks

### Setup you repository

- Open a pull request to add your repository configuration via `cms-bot/repos/<user>/<repo>/repo_config.py`
    - If you have `-` character in your github user or repository name then replace it with `_`
- It is better to copy existing configuration and change it accordingly e.g. copy `repos/smuzaffar/SCRAM` in to `repos/<user>/<repo>`
- If you want `cmsbot` github user to update your repository/pull requests/issue (e.g. adding webhooks, setting labels etc.) then please
    - **github organization**: Add github user `cmsbot` in to a team with `write` (or `admin`) rights
    - **personal repository**: Add `cmsbot` as `Collaborators` (under the `Settings` of your repository).
- Add github webhook so that bot can receive notifications
    - **`cmsbot` with `admin` rights**: Set `ADD_WEB_HOOK=True` in `repos/<user>/<repo>/repo_config.py` so that bot can automatically add web-hook
    - **`cmsbot` without `admin` right**: Add yourself the github webhook (under `Settings` of your repository) so that bot can recognize/process webhooks
        - Please disable SSL Verificaton as github does not recognize cmssdt.cern.ch certificate
        - Payload URL: https://cmssdt.cern.ch/SDT/cgi-bin/github_webhook
        - Content type: application/json
        - Secret: any password of your choice
        - Disable SSL Verification
        - Let me select individual events: Select
            - Issues, Issue comment, Pull request 
            - Pushes (for push based events)
        - Once you have created the webhook then please encrypt your secret by running `curl -d 'TOKEN=your-secret' https://cmssdt.cern.ch/SDT/cgi-bin/encrypt_github_token` and add `GITHUB_WEBHOOK_TOKEN=encrypted-token` in the `repos/<user>/<repo>/repo_config.py` file.

### Pull request Testing:

- For `user/cmssw` and `user/cmsdist` repositories , bot can run standard PR tests.
    - If you do not want to run standard cms PR tests then set `CMS_STANDARD_TESTS=False` in your `repo_config.py` file.
- For `user/non-cmssw` repository, you need to provide `repos/<user>/<repo>/run-pr-tests` script which bot can run.
    - bot will clone your repository in `$WORKSPACE/userrepo` and will merge your pull request on top of your default branch
    - A file `$WORKSPACE/changed-files.txt` will contain the list of changed file in the Pull Request
    - If you want to upload job logs (max 1G) then copy them under `$WORKSPACE/upload`
- cmsbot commands are listed here http://cms-sw.github.io/cms-bot-cmssw-cmds.html

### Push based testsing

- You can have your repository setup to trigger the tests whenever you push some changes to your repo. In this case, please make sure that github webhook for *Pushes* is active.