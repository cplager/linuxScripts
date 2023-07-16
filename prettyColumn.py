#! /usr/bin/env python

import re
import optparse
import sys
import pprint as pprint

def swap (lines):
    """Rotates around y = -x line"""
    # get maximum length of lines
    maxLine = 0
    for line in lines:
        if len (line) > maxLine:
            maxLine = len (line)
    retval = []
    numLines = len (lines)
    for column in range (maxLine):
        newLine = []
        for line in lines:
            if len (line) < column:
                newLine.append ('')
            else:
                newLine.append (line[column])
        retval.append (newLine)
    return retval

if __name__ == "__main__":
    parser = optparse.OptionParser("usage: %prog [options]")
    parser.add_option ('--swap', dest='swap', action='store_true',
                       help='Swap X and Y row/columns')
    parser.add_option ('--lstrip', dest='lstrip', action='store_true',
                       help='Runs lstrip on input strings')
    (options, args) = parser.parse_args()
    spacesRE = re.compile (r'\s+')
    lines = []
    for line in sys.stdin:
        if options.lstrip:
            line = line.strip()
        else:
            line = line.rstrip()
        words = spacesRE.split (line)
        lines.append (words)

    ## pprint.pprint (lines)
    ## pprint.pprint (maxWordLength)

    if options.swap:
        lines = swap (lines)

    # calculate max word lengths
    maxWordLength = []
    for words in lines:
        for index, word in enumerate (words):
            length = len (word)
            if len(maxWordLength) <= index:
                maxWordLength.append (length)
            elif length > maxWordLength[index]:
                maxWordLength[index] = length

    for words in lines:        
        for index, word in enumerate (words):
            if index:
                offset = maxWordLength[index] + 2
            else:
                offset = maxWordLength[index]
            form = '%' + str(offset) + 's'
            print form % word,
        print
