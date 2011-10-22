# ValidateMessage.py
#
# Mercurial extension to check commit messages for format compliance.
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

from mercurial import commands, extensions, util

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

# Validate Mercurial commit message.
def validate_message(original_commit, ui, repo, *pats, **opts):
    # Retrieve commit message.
    message = opts['message']

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