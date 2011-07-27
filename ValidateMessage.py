# ValidateMessage.py
#
# Mercurial extension to check commit messages for format compliance.
#
# Commit messages must begin with an issue number in #number: format
# unless they contain @merge, @tag or @ignore within the message text.
#
# To use:
#
# 1. Edit configuration section to be correct for your environment.
#
# 2. Add this extension to your Mercurial.ini file.
#
#     [extensions]
#     validatemessage = path\ValidateMessage.py

import re
import subprocess

from mercurial import commands, extensions, util

# Configuration
_database_server = '5746-WIN7\PENGUIN'
_database_name = 'Redmine'
_database_user = 'sa'
_database_password = 'penguin'

# Validate issue number
def validate_issue(ui, issue):
    # Is issue number not in database?
    connection = ('sqlcmd -U' + _database_user + ' -P' + _database_password +
        ' -S' + _database_server + ' -d' + _database_name + ' /w 8192')
    sql = 'set nocount on select id from dbo.issues where id = %s' % str(issue)
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
    if not re.search('\A@merge|\s@merge|\A@tag|\s@tag|\A@ignore|\s@ignore', message):

        # Does commit message not start with an issue number?
        match = re.search('\A#([0-9]*):', message)
        if not match:
            # Abort commit and exit.
            raise util.Abort('Commit message did not contain an issue number.')

        # Validate issue number
        # validate_issue(ui, match.group(1))

    # Proceed with commit.
    return original_commit(ui, repo, *pats, **opts)

# Handle Mercurial setup callback.
def uisetup(ui):
    # Add our function to commit process.
    extensions.wrapcommand(commands.table, 'commit', validate_message)