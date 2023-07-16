#! /usr/bin/env python

import optparse, os, glob, commands, time, datetime, shutil, re, sys

# 'set' is new in Python 2.4, but almost exists in 2.3
import sys, string
version = string.split(string.split(sys.version)[0], ".")
if '2' == version[0] and '3' == version[1]:
    from sets import Set as set


###############################
## ######################### ##
## ## Private Subroutines ## ##
## ######################### ##
###############################

def _backupName (filename):
    """Returns a backup filename."""
    if _currentTime:
        key = _currentTime
    else:
        filetime = datetime.datetime.fromtimestamp(os.stat(filename).st_mtime)
        # Convert filetime into epoch seconds to int to hex, and drop
        # leadiing'0x'
        key = hex( int( time.mktime( filetime.timetuple() ) ) )[2:]
    return "%s/%s.%s" % (_backupDirectory, filename, key)


def _backupTag (backup):
    """Returns the tag from a backup file iff it is valid"""
    extMatch = re.search (r'\.([^\.]+)$', backup)
    if extMatch and re.match (r'^[0-9a-fA-F]{8}$', extMatch.group(1)):
        return extMatch.group(1).lower()
    else:
        return None


def _listOfBackupFiles (filename):
    """Returns a sorted (newest to oldest) list of existing backup files"""
    globMatch = r'%s/%s.*' % (_backupDirectory, filename)
    files = glob.glob (globMatch)
    backupFiles = []
    for backup in files:
        if _backupTag (backup):
            backupFiles.append (backup)
    if backupFiles:
        backupFiles.sort (reverse = True)
        return backupFiles


def _splitFilename (fullFilename):
    """Returns 'path' and 'filename' as well as changes to the correct
    directory."""
    path, name = os.path.split (fullFilename);
    # if this file is in the same directory we started _OR_ is new
    # directory with a relative path:
    if not path or '/' != path[0]:
        # Are we where we started?
        if os.getcwd() != _startingDir:
            # No?  Fix it.
            os.chdir (_startingDir)
        # if I need to go somewhere else, go there
        if path:
            os.chdir (path)
    else:
        os.chdir (path)
    return path, name


def _fileIsOK (fullFilename, **kwargs):
    """Checks a full filename to make sure it's appropriate"""
    # make sure this file exists (unless we set in 'exists' to True)
    if not kwargs.get('exists') and not os.path.exists (fullFilename):
        print "File '%s' does not exist.  Skipping." % fullFilename     
        return False
    # We don't do directories here
    if os.path.isdir (fullFilename):
        print "File '%s' is a directory.  Skippng." % fullFilename
        return False
    # if we're stil here, then we're golden
    return True


def _getBackupFile (filename) :
    """Returns a list of available backup files.  Must be called after
    '_splitFilename()'"""
    backupFiles = _listOfBackupFiles (filename)
    # Are there any files?
    useBackup = ""
    if not backupFiles:
        print "Could not find any backup files for '%'.  Skipping." % \
              fullFilename
        return none
    # Did you pass in a key?
    if _matchKey:
        for backup in backupFiles:
            if _backupTag (backupFiles) == _matchKey:
                # we've got it. Stop looking
                useBackup = backup
                break
    # Do we want the latest before a given date?
    elif _matchEpoch:
        maxEpoch = 0;       
        for backup in backupFiles:
            tag = _backupTag (backupFiles)
            if not tag: continue
            backupEpoch = int (tag, 16)
            # Is this one less than our date?
            if backupEpoch <= _matchEpoch:
                # is this the most recent which is still less than our
                # date?
                if backupEpoch > maxEpoch:
                    maxEpoch = backupEpoch
                    useBackup = backup
            # if new best match
    else:
        useBackup = backupFiles[0]
    if not useBackup:
        print "Could not find backup file for '%' meeting criteria. "\
              " Skipping." % fullFilename
        return none
    return useBackup


def _loadAllNotes():
    """Loads all notes.  Must be called after '_splitFilename()'"""
    # clear out dictionary
    global _notesDict
    _notesDict = {}
    notesfile = "%s/%s" % (_backupDirectory, _backupNotesFile)
    if not os.path.exists (notesfile):
        # Nothing more to see here folks.  Move along.
        return
    notes = open (notesfile, "r")
    for line in notes:
        line = line.strip();
        notesMatch = re.search (r'([^:]+):(.+)', line)
        if notesMatch:
            _notesDict[ notesMatch.group(1) ] = \
                        notesMatch.group(2)


#####################################
## ############################### ##
## ## User Callable Subroutines ## ##
## ############################### ##
#####################################


def stringToEpoch (string) :
    """Converts a string to epoch seconds"""
    try:        
        timetuple = time.strptime (string, "%b %d %Y")
    except ValueError:
        try:
            year = datetime.date.today().year
            print year
            withyear = "%s %d" % (string, year)     
            timetuple = time.strptime (withyear, "%b %d %H:%M %Y")
        except ValueError:
            print "Can't convert '%s' to epoch seconds.  Aborting" % string
            sys.exit()
        # if we're here, then the year is messed up
        time
    return int( time.mktime( timetuple ) )


def backupFile (fullFilename, **kwargs):
    """Copies a file to _backupDirectory if not already there"""
    quiet = kwargs.get('quiet')
    if not _fileIsOK (fullFilename) :
        return
    # Split the filename into path and basename and make sure we're in
    # the right directory
    path, name = _splitFilename (fullFilename)
    if not name:
        print "Something is wrongg withFile '%s'.  Skippng." % fullFilename
        return
    if not os.path.isdir (_backupDirectory):
        # Make the directory
        # print "making backup directory", os.getcwd()
        os.mkdir (_backupDirectory)
    else:
        # Directory exists, see if we need to backup the file or not
        backupFiles = _listOfBackupFiles (name)
        if backupFiles and not _forceCurrent:
            last = backupFiles[0]
            # Is the backup file the same as the current file?
            if not commands.getoutput ( "diff %s %s" % (name, last) ):
                # This file is the same, no need to back it up again
                return
        # if backupFiles
    # If we're still here then we 1) have a file and 2) it needs to be
    # backed up
    backup =  _backupName (name)
    # Does the backup file already exist?
    if os.path.exists (backup):
        print "Backup file '%s' already exists for '%s'.  Skipping." % \
              (backup, fullFilename)
        return
    # Back it up
    if not quiet:
        print "backing up file %s to %s" % (fullFilename, backup)
    if not options.noCopy:
        shutil.copy2 (name, backup)
        os.chmod (backup, 444)
    # write a message if available
    if _message:
        messageString = "%s: %s" % (os.path.basename (backup), _message)
        if not quiet:
            print "Writing '%s' into notesfile" % messageString
        notes = open ("%s/%s" % (_backupDirectory, _backupNotesFile), "a")
        notes.write ("%s\n" % messageString)
        notes.close()
    return backup


def restoreBackupFile (fullFilename):
    """Restores a backup file."""
    if not _fileIsOK (fullFilename, exists=True) :
        return
    # Split the filename into path and basename and make sure we're in
    # the right directory
    path, name = _splitFilename (fullFilename)
    useBackup  = _getBackupFile (name)
    if not useBackup:
        return
    print "Restoring '%s' to '%s'." % (useBackup, fullFilename)
    if not options.noCopy:
        shutil.copy2 (useBackup, name)


def diffBackupFile (fullFilename):
    """Diff between current file and backup"""
    if not _fileIsOK (fullFilename) :
        return
    # Split the filename into path and basename and make sure we're in
    # the right directory
    path, name = _splitFilename (fullFilename)
    useBackup  = _getBackupFile (name)
    if not useBackup:
        return
    diffCommand = "diff %s %s" % (name, useBackup)
    print diffCommand
    os.system ( diffCommand )
    print


def listVersions (fullFilename):
    """list all versions (and notes) for given file"""
    if not _fileIsOK (fullFilename, exists=True) :
        return
    # Split the filename into path and basename and make sure we're in
    # the right directory
    path, name = _splitFilename (fullFilename)
    backupFiles = _listOfBackupFiles (name)
    if not backupFiles:
        print "No backup files found for '%s'.  Skipping." % fullFilename
    print "Backup files for '%s':\n" % fullFilename
    _loadAllNotes()
    for backup in backupFiles:
        tag = _backupTag (backup)
        key = "%s.%s" % (name, tag)
        message = _notesDict.get (key)
        if message:
            print '%s : "%s"' % (tag, message)
        else:
            print '%s' % (tag)
        os.system ("ls -l %s" % backup)
        print
    # Does the current file exist?
    if os.path.exists (name):
        print "Current file:"
        os.system ("ls -l %s" % name)
        print

def backupDirectory (directoryName):
    if os.path.islink(directoryName):
        # don't bother
        return
    if (os.path.basename(directoryName) == _backupDirectory):
        # backing up teh backup directory would lead to all sorts of
        # problems, so don't do that.
        return
    if not os.path.isdir (directoryName):
        print "'%s' is not a directory.  Skipping." % directoryName
    fullPathName = os.path.abspath (directoryName);
    os.chdir (fullPathName) 
    print "\nDirectory '%s':" % fullPathName
    allfiles = glob.glob("*")
    dirNames = []
    for filename in allfiles:
        if os.path.islink (filename):
            # Again, don't bother
            continue
        if os.path.isdir (filename):
            dirNames.append ("%s/%s" % (fullPathName, filename))
            #print "Directory found: %s" % filename
            continue
        # if we're still here, this file is not a soft link or a
        # directory.  Get the extention to see if we're interested
        extMatch = re.search (r'\.([^\.]+)$', filename)
        if extMatch and extMatch.group(1).lower() in _usualExt:
            fullFilename = "%s/%s" % (fullPathName, filename)
            status = backupFile (fullFilename, quiet=True)
            if status:
                print "  %-20s : %s" % (filename, status)
            else:
                print "  %-20s :" % (filename)
            os.chdir (fullPathName)
    for dir in dirNames:
        print "dir", dir
        backupDirectory (dir)
    os.chdir (fullPathName)



##############################################################################
## ######################################################################## ##
## ##                                                                    ## ##
## ######################################################################## ##
##############################################################################


# Global state variables
_backupDirectory = ".backup"
_backupNotesFile = ".backupNotes"
_startingDir     = os.getcwd();
_currentTime     = ""
_forceCurrent    = False
_matchKey        = ""
_matchEpoch      = 0
_message         = ""
_notesDict       = {}
_usualExt        = set ( ['buildfile', 'c', 'cc', 'h', 'hh', 'html',
                          'makefile', 'pl', 'pm', 'py',
                          'tex', 'txt', 'xml'] )


########################
## ################## ##
## ## Main Program ## ##
## ################## ##
########################


if __name__ == "__main__":
    # Setup options parser
    parser = optparse.OptionParser("usage: %prog [options] file1 [file2]\n"\
                                   "File backup utility.")
    backupGroup = optparse.OptionGroup (parser, "Backup Options")
    restoreGroup = optparse.OptionGroup (parser, "Restore Options")
    restoreGroup = optparse.OptionGroup (parser, "Restore/Diff Options")    
    parser.add_option ("--diff", dest="diff",
                       action="store_true", default=False,
                       help="run diff against backup file")
    parser.add_option ("--restore", dest="restore",
                       action="store_true", default=False,
                       help="restore file from backup")
    parser.add_option ("--listVersions", dest="listVersions",
                       action="store_true", default=False,
                       help="show versions of files that are in backup")
    parser.add_option ("--backupDirectory", dest="backupDirectory",
                       action="store_true", default=False,
                       help="Backup all files in this directory and under")
    backupGroup.add_option ("-m", "--message", dest="msg", type="string",
                       help="message associated with backup file")
    backupGroup.add_option ("--currentTime", dest="currentTime",
                       action="store_true", default=False,
                       help="use current time instead of file mod time")
    backupGroup.add_option ("--forceCurrent", dest="force",
                       action="store_true", default=False,
                       help="force backup of files using _currentTime stamp")
    backupGroup.add_option ("--noCopy", dest="noCopy",
                       action="store_true", default=False,
                       help="Does everything except making backup copy")    
    restoreGroup.add_option ("--key", dest="key", type="string",
                       help="restore files to backup key 'restoreKey'")
    restoreGroup.add_option ("--date", dest="date", type="string",
                       help="restore files condition on date 'restoreDate'." +
                             " Format: 'Sep 10 2003' or 'Sep 28 20:14'")
    restoreGroup.add_option ("--datestring", dest="datestring", type="string",
                       default="",
                       help="for testing if I can correctly convert your"\
                             " date string")
    # Start parsing
    parser.add_option_group (backupGroup)
    parser.add_option_group (restoreGroup)
    (options, args) = parser.parse_args()
    _currentTime  = options.currentTime
    _forceCurrent = options.force
    _message      = options.msg
    _matchKey     = options.key
    # Deal with special case
    if options.currentTime or options.force:
        now = datetime.datetime.now()
        _currentTime =  key = hex( int( time.mktime( now.timetuple() ) ) )[2:]
        print "Current time key: %s", _currentTime  
    if options.date:
        _matchEpoch = stringToEpoch (options.date)

    if options.backupDirectory:
        if args:
            backupDirectory (args[0])
        else:
            backupDirectory (".")
        sys.exit (0)

    # Main loop
    for fullFilename in args:
        if options.restore:
            restoreBackupFile (fullFilename)
        elif options.diff:
            diffBackupFile (fullFilename)
        elif options.listVersions:
            listVersions (fullFilename)     
        else:
            backupFile (fullFilename)

    # Testing of datestring
    if options.datestring:
        print stringToEpoch (options.datestring)
