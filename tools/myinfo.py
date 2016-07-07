#!/usr/bin/env python
# -*- coding: latin-1 -*-

################################################################################
#
# myinfo.py
# 
# 
# (C) 2016 Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

import os, sys, yaml, re
from pprint import pprint
from collections import defaultdict

from Cheetah.Template import Template

#sys.path.append("pysmx")
#import smx



myinfo_vars = {
	"author": "Jared Ballou (jballou)",
	"description": "New Plugin",
	"name": "New Plugin",
	"url": "http://jballou.com/insurgency",
	"version": "0.0.1",
}

myinfo_defines = {
	"PLUGIN_WORKING": "0",
	"PLUGIN_FILE": "",
	"PLUGIN_LOG_PREFIX": "",
	"UPDATE_URL_FORMAT(%1)": "http://ins.jballou.com/sourcemod/update-%1.txt",
	"UPDATE_URL": "UPDATE_URL_FORMAT(PLUGIN_FILE)"
}

myinfo_define = """
#if !defined %(k)s
#define %(k)s "%(v)s"
#endif"""

myinfo_func = "public Plugin:myinfo"

for k,v in myinfo_vars.iteritems():
	myinfo_defines["PLUGIN_%s" % (k.upper())] = v

# Main function
def main():
	tmpl = str(Template ( file = "templates/myinfo.tmpl", searchList = [{ 'myinfo_defines': myinfo_defines, 'myinfo_vars': myinfo_vars, 'myinfo_define': myinfo_define, 'myinfo_func': myinfo_func}] ))
	print tmpl
	for name in config['plugins']['build']:
		mi = MyInfo(name)

class MyInfo(object):
	def __init__(self, name):
		self.name = name
		print "loading %s" % self.name
		self.myinfo_defines = myinfo_defines
		self.myinfo_vars = myinfo_vars
		#self.get_myinfo_vars()
		#self.get_myinfo_defines()
	def get_myinfo_vars(self):
		for k,v in self.myinfo_vars.iteritems():
			print "%s = PLUGIN_%s," % (k,k.upper())
	def get_myinfo_defines(self):
		for k,v in self.myinfo_defines.iteritems():
			print myinfo_define % {"k": k, "v": v}



def get_yaml_file(yaml_file):
	with open(yaml_file, 'r') as stream:
		try:
			return(yaml.load(stream))
		except yaml.YAMLError as exc:
			print(exc)
			sys.exit()

config = get_yaml_file("config.yaml")

if __name__ == "__main__":
	main()

"""
        def process_plugin(self):
                with open(self.smx_file, 'rb') as fp:
                        try:
                                self.plugin = smx.SourcePawnPlugin(fp)
                                self.files['Plugin'].append("plugins/%s" % os.path.basename(self.smx_file))
                        except:
                                print("Could not load \"%s\"!" % self.smx_file)
                                return
                self.myinfo = self.plugin.myinfo

        # Compile plugin if missing our out of date, default to disabled
        def check_plugin_compile(self):
                pass

        def create_updater_file(self):
                fp = open(getpath("updater-data/update-%s.txt" % self.name), 'w')
from Cheetah.Template import Template
                tmpl = str(Template ( file = "templates/update.tmpl", searchList = [{ 'plugin': self }] ))
                fp.write(tmpl)
                fp.close()
                return

"""
