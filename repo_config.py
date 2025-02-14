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
