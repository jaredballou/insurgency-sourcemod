#!/usr/bin/env python
# -*- coding: latin-1 -*-
################################################################################
#
# make-docs.py
# 
# This script pulls the information from the plugin source files and
# creates updater manifests and the Readme. Take a look in plugins for a better
# idea of how this works.
# 
# (C) 2015,2016 Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

import argparse
import logging
import os
from pprint import pprint
import sys
sys.path.append(os.path.join(os.getcwd(),"pysmx"))
import sourcemod

# TODO: Document and format all Python files
# TODO: Add command-line arguments and defaults
# TODO: Cleanly integrate config, command line, and instances to properly inherit settings
# TODO: Compare the source file and compiled plugin more intelligently than raw file times.
# TODO: Manage all plugin types, and put in appropriate locations (disabled, nobuild, thirdparty)
# TODO: Collect errors from compilation and show to user
# TODO: Allow configurable compiler command
# TODO: Add command-line arguments to control script
# TODO: Move scripting files around according to their status in the config
# TODO: Identify upstream plugins as a separate set
# TODO: Flag all unclassified plugins and script files
# TODO: Handle extensions
# TODO: Process gamedata files, translations, etc.

# Main function
def main():
    parser = argparse.ArgumentParser(
        description='SourceMod Repo Manager'
    )
    parser.add_argument("-v", "--verbose", help="increase output verbosity", action="store_true")
    args = parser.parse_args()
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    logging.debug('Only shown in debug mode')
    sm = sourcemod.SourceMod()

if __name__ == "__main__":
    main()
