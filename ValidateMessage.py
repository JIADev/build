# ValidateMessage.py
#
# Mercurial extension to check commit messages for format compliance and other concerns
#
# Commit messages must have an issue number in "#number:" format unless
# they contain "@merge", "@tag" or "@ignore" within the message text. A
# prefix like "Task", "UAT Support", "refs", "fixes", etc. may optionally
# be placed before the "#".
#
# Commit message format:
#
#    optional-prefix #number: commit-message-text
#
# To use:
#
#    1. Edit configuration section to be correct for your environment.
#
#    2. Add this extension to your Mercurial.ini file.
#
#       [extensions]
#       validatemessage = path\ValidateMessage.py

import re
import subprocess
import os

from mercurial import commands, extensions, util
import mercurial

# Configuration.
_database_server = 'JIA-SQL5'
_database_name = 'RedmineReport'

# Validate issue number.
def validate_issue(ui, issue):
    # Is issue number not in database?
    connection = ('sqlcmd' +
        ' -S' + _database_server + ' -d' + _database_name + ' /w 8192')
    sql = 'set nocount on select id from Redmine.issues where id = %s' % str(issue)
    result = subprocess.Popen(connection + ' -Q' + '"' + sql + '"',
        stdout=subprocess.PIPE).stdout.readlines()
    if len(result) < 3:
        # Abort commit and exit.
        raise util.Abort('Commit message issue number was not found.')

def validate_same_branch(ui, repo, *pats, **opts):
    master = repo[None].branch()
    sub = mercurial.hg.repository(ui, "j6")
    j6 = sub[None].branch()
    if master != j6:
        raise util.Abort("Master branch %s doesn't match j6 branch %s" % (master,j6))

def validate_not_direct_version_commit(ui, repo, *pats, **opts):
    rev = repo[None]
    branch = rev.branch()
    direct = re.search(r"^\d\.\d\.\d$", branch) and not opts['close_branch']
    direct = direct and len(rev.parents()) <= 1 and not rev.tags()
    if direct:
        if ui.prompt('Warning, committing directly to a numbered version. Would you like to proceed? [Ny]', default = 'n') not in ('y', 'Y'):
            raise util.Abort('Aborted by user request.')

def validate_built_and_tested(ui, repo, *pats, **opts):
    rev = repo[None]
    if ui.prompt("Would you like to build j6 and run the unit tests before committing? [Yn]", default = 'y') in ('y', 'Y'):
        tools = os.getcwd() + r"\tools.sln"
        is_7_6_or_greater = os.path.exists(tools)
        try:
            if is_7_6_or_greater:
                subprocess.check_call(["msbuild", "/t:Build", "j6.proj"])
            else:
                subprocess.check_call([r"j6\core\boot\feature", "build"])
        except:
            raise util.Abort("Build failed")
        try:
            if is_7_6_or_greater:
                test = subprocess.check_call(["msbuild", "/t:UnitTest", "j6.proj"])
            else:
                test = subprocess.check_call([r"j6\core\boot\feature", "test"])
        except:
            raise util.Abort("Tests failed")
        return opts['message'] + "\r\n** j6 unit tests pass **"

# Validate Mercurial commit message.
def validate_message(original_commit, ui, repo, *pats, **opts):
    if opts['subrepos']:
        validate_same_branch(ui, repo, *pats, **opts)
    validate_not_direct_version_commit(ui, repo, *pats, **opts)
    updated_message = validate_built_and_tested(ui, repo, *pats, **opts)

    # Retrieve commit message.
    message = updated_message or opts['message']
    opts['message'] = message
    # Are we not doing a merge, tag or ignore?
    if not re.search('@[Mm]erge|@[Tt]ag|@[Ii]gnore', message):

        # Does commit message not start with an issue number?
        match = re.search('\A[\w\s]*#\s*([0-9]*)[\s:;]', message)
        if not match:
            # Abort commit and exit.
            raise util.Abort('Commit message did not contain an issue number.')

        # Validate issue number.
        validate_issue(ui, match.group(1))

    # Proceed with commit.
    return original_commit(ui, repo, *pats, **opts)

# Handle Mercurial setup callback.
def uisetup(ui):
    # Add our function to commit process.
    extensions.wrapcommand(commands.table, 'commit', validate_message)