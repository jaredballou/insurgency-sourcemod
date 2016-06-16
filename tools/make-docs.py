#!/usr/bin/env python
# -*- coding: latin-1 -*-

################################################################################
#
# generate-documentation.py
# 
# This script reads the two lists in this directory, my plugins and third party
# ones. This script pulls the information from the plugin source files and
# creates updater manifests and the Readme. Take a look in plugins for a better
# idea of how this works, note that dependencies and cvars are regenerated from
# scratch each run, so don't make any manual edits to those files.
# 
# (C) 2015,2016 Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

import os, sys, yaml, re
from pprint import pprint
from collections import defaultdict

from Cheetah.Template import Template

sys.path.append("pysmx")
import smx

# Set variables

# Paths
root = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
#print root
paths = {
	'root':		root,
	'doc':		os.path.join(root,"doc"),
	'plugins':	os.path.join(root,"plugins"),
	'scripting':	os.path.join(root,"scripting"),
	'include':	os.path.join(root,"scripting","include"),
	'gamedata':	os.path.join(root,"gamedata"),
	'tools':	os.path.join(root,"tools"),
	'translations':	os.path.join(root,"translations"),
	'updater':	os.path.join(root,"updater-data"),
}

# GitHub URL to pull from
github_user = "jaredballou"
github_repo = "insurgency-sourcemod"
github_branch = "master"

urls = {
	'github':	"https://github.com/%s/%s/blob/%s" % (github_user,github_repo,github_branch),
	'updater':	"http://ins.jballou.com/sourcemod",
}

# File paths

files = {
	'compiler':	os.path.join(paths['scripting'],'spcomp'),
	'config':	os.path.join(paths['tools'],"config.yaml"),
	'readme':	os.path.join(paths['root'],"README.md"),
}

# Get YAML file
def get_yaml_file(yaml_file):
	with open(yaml_file, 'r') as stream:
		try:
			return(yaml.load(stream))
		except yaml.YAMLError as exc:
			print(exc)
			sys.exit()
config = get_yaml_file(files['config'])

# Main function
def main():
	for name in config['plugins']['build']:
		plugin = SourceModPlugin(name)


class SourceModPlugin(object):

	def __init__(self,name=None):
		self.cvars = {}
		self.commands = {}
		self.todo = {}
		self.files = {"Plugin": [], "Source": []}
		self.dependencies = {"Plugin": [], "Source": []}
		self.compile = False
		self.myinfo = {}
		self.todos = {}
		if not name is None:
			self.name = name
		else:
			self.name = "UNKNOWN"
		self.get_files()
		self.process_source()
		self.process_plugin()
		self.create_updater_file()
		self.create_plugin_file()


	# Get values from plugin
	def get_files(self):
		sp_file = os.path.join(paths['root'],"scripting","%s.sp" % self.name)
		if not os.path.isfile(sp_file):
			print("ERROR: Cannot find plugin source file \"%s\"!" % sp_file)
			return dict()
		smx_file = os.path.join(paths['root'],"plugins","%s.smx" % self.name)
		if not os.path.isfile(smx_file):
			smx_file = os.path.join(paths['root'],"plugins/disabled","%s.smx" % self.name)
		if not os.path.isfile(smx_file):
			self.compile = True
		self.sp_file = sp_file
		self.smx_file = smx_file

	def process_source(self):
		with open(self.sp_file, 'r') as stream:
			try:
				self.source = stream.read()
				self.files['Source'].append("scripting/%s" % os.path.basename(self.sp_file))
			except:
				print("Could not load \"%s\"!" % self.sp_file)
				return
		for func_type,func_name in {'commands': 'RegConsoleCmd', 'cvars': 'CreateConVar', 'translations': 'LoadTranslations', 'gamedata': 'LoadGameConfigFile'}.iteritems():
			for func in re.findall(r"%s\s*\((.*)\);" % func_name, self.source):
				parts = [p.strip("""'" \t""") for p in func.split(',')]
				if func_type == 'cvars':
					self.cvars[parts[0]] = {'value': parts[1], 'description': parts[2]}
				elif func_type == 'commands':
					self.commands[parts[0]] = {'function': parts[1]}
					if len(parts) > 2:
						self.commands[parts[0]]["description"] = parts[2]
				else:
					file = "%s/%s.txt" % (func_type, parts[0])
					if not file in self.files['Plugin']:
						self.files['Plugin'].append(file)

		for include in re.findall(r"#include[\t ]*<([^>]+)>", self.source):
			incfile = "scripting/include/%s.inc" % include
			if include in config['libraries']['ignore'] or incfile in self.files['Source']:
				continue
			self.files['Source'].append(incfile)

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
		fp = open(os.path.join(paths['updater'],"update-%s.txt" % self.name), 'w')
		tmpl = str(Template ( file = "templates/update.tmpl", searchList = [{ 'plugin': self }] ))
		fp.write(tmpl)
		fp.close()
		return

	def create_plugin_file(self):
		fp = open(os.path.join(paths['doc'],"%s.md" % self.name), 'w')
		tmpl = str(Template ( file = "templates/plugin.tmpl", searchList = [{ 'plugin': self }] ))
		fp.write(tmpl)
		fp.close()
		return

if __name__ == "__main__":
	main()
