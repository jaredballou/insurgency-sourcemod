#!/usr/bin/env python
# -*- coding: latin-1 -*-
################################################################################
#
# generate-documentation.py
# 
# This script pulls the information from the plugin source files and
# creates updater manifests and the Readme. Take a look in plugins for a better
# idea of how this works.
# 
# (C) 2015,2016 Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

from pprint import pprint
import sys
import os
import sourcemod

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
	sm = sourcemod.SourceMod()
	sm.write_readme()

if __name__ == "__main__":
	main()
