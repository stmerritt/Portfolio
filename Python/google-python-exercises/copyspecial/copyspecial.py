#!/usr/bin/python
# Copyright 2010 Google Inc.
# Licensed under the Apache License, Version 2.0
# http://www.apache.org/licenses/LICENSE-2.0

# Google's Python Class
# http://code.google.com/edu/languages/google-python-class/

import sys
import re
import os
import shutil
# import commands

from datetime import datetime

"""Copy Special exercise
"""

# +++your code here+++
# Write functions and modify main() to call them
def copyToDir(todir, dirs):
  if todir != '':
    for dir in dirs:
      shutil.copy(dir, todir)

def copyToZip(tozip, dirs, dt_string):
  if tozip != '':
    i = 0
    for dir in dirs:
      dir_name = 'zip_dir_' + str(i) + dt_string
      i = i + 1
      shutil.make_archive(dir_name, 'zip', dir)
      shutil.move(dir + '/' + dir_name, tozip)

def main():
  # This basic command line argument parsing code is provided.
  # Add code to call your functions below.

  # Make a list of command line arguments, omitting the [0] element
  # which is the script itself.
  now = datetime.now()
  dt_string = now.strftime("%d_%m_%Y__%H:%M:%S")

  args = sys.argv[1:]
  if not args:
    print("usage: [--todir dir][--tozip zipfile] dir [dir ...]")
    sys.exit(1)

  # todir and tozip are either set from command line
  # or left as the empty string.
  # The args array is left just containing the dirs.
  todir = ''
  if args[0] == '--todir':
    todir = args[1]
    del args[0:2]

  tozip = ''
  if args[0] == '--tozip':
    tozip = args[1]
    del args[0:2]

  if len(args) == 0:
    print("error: must specify one or more dirs")
    sys.exit(1)

  # +++your code here+++
  # Call your functions
  copyToDir(todir, args)

  copyToZip(tozip, args, dt_string)
  
if __name__ == "__main__":
  main()
