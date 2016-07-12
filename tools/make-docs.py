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
from collections import defaultdict, OrderedDict

from Cheetah.Template import Template

sys.path.append(os.path.join(os.getcwd(),"pysmx"))
import smx

# TODO: Compare the source file and compiled plugin more intelligently than raw file times.
# TODO: Manage all plugin types, and put in appropriate locations (disabled, nobuild, thirdparty)

# Main function
def main():
	sm = SourceMod()

class SourceMod(object):
	def __init__(self,config_file=None):
		self.load_config(config_file=config_file)
		self.load_plugins()
		self.create_readme()

	def load_plugins(self):
		self.plugins = {}
		for name in self.config['plugins']['build']:
			self.plugins[name] = SourceModPlugin(name=name,config=config)

	def load_config(self,config_file=None):
		if config_file is None:
			config_file = getpath("tools/config.yaml")
		self.config_file = config_file
		self.config = get_yaml_file(self.config_file)

	def getpath(self,path=""):
		root = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
		return os.path.join(root,path)

	def get_yaml_file(self,yaml_file):
		with open(yaml_file, 'r') as stream:
			try:
				return(yaml.load(stream))
			except yaml.YAMLError as exc:
				print(exc)
				sys.exit()
	def create_readme(self):
		sortedKeys = sorted(self.plugins.keys())
		fp = open(getpath("README.md"), 'w')
		tmpl = str(Template ( file = "templates/readme.tmpl", searchList = [{ 'plugins': self.plugins, 'sortedKeys': sortedKeys }] ))
		fp.write(tmpl)
		fp.close()

	def interpolate(self, key=None, data=None, interpolate_data=None):
		val = ""
		if data is None:
			data = self.config
		if interpolate_data is None:
			interpolate_data = data

		if key is None:
			item = data
		else:
			if not key in data.keys():
				return
			item = data[key]

		kt = type(item)
		if kt in [str, int]:
			val = item
		if kt in [list]:
			val = ', '.join(map(str, item))
		if kt in [set,tuple]:
			val = item.join(", ")
		if kt in [OrderedDict, dict]:
			vals = dict()
			for skey in item.keys():
				vals[skey] = self.interpolate(key=skey,data=item,interpolate_data=interpolate_data)
			return vals
 		try:
			while (val.find('%') != -1):
				val = (val) % interpolate_data
		except:
			return val
		return val

class SourceModPlugin(object):

	def __init__(self,name=None,config=None):
		self.config = config
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
		sp_file = getpath("scripting/%s.sp" % self.name)
		if not os.path.isfile(sp_file):
			print("ERROR: Cannot find plugin source file \"%s\"!" % sp_file)
			return dict()
		smx_file = getpath("plugins/%s.smx" % self.name)
		if not os.path.isfile(smx_file):
			smx_file = getpath("plugins/disabled/%s.smx" % self.name)
		if not os.path.isfile(smx_file) or os.stat(sp_file).st_mtime > os.stat(smx_file).st_mtime:
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
		for func_type,func_name in {'commands': 'Reg[A-Za-z]*Cmd', 'cvars': 'CreateConVar', 'translations': 'LoadTranslations', 'gamedata': 'LoadGameConfigFile'}.iteritems():
			for func in re.findall(r"(%s)\s*\((.*)\);" % func_name, self.source):
				parts = [p.strip("""'" \t""") for p in func[1].split(',')]
				if func_type == 'cvars':
					if parts[0].endswith('_version'):
						continue
					self.cvars[parts[0]] = {'value': parts[1], 'description': parts[2]}
				elif func_type == 'commands':
					self.commands[parts[0]] = {'function': parts[1]}
					if func[0] == 'RegAdminCmd':
						desc_idx = 3
					else:
						desc_idx = 2
					if len(parts) > desc_idx:
						self.commands[parts[0]]["description"] = parts[desc_idx]
				else:
					file = "%s/%s.txt" % (func_type, parts[0])
					if not file in self.files['Plugin']:
						self.dependencies['Plugin'].append(file)

		for include in re.findall(r"#include[\t ]*<([^>]+)>", self.source):
			incfile = "scripting/include/%s.inc" % include
			if include in self.config['libraries']['ignore'] or incfile in self.files['Source']:
				continue
			if include == self.name:
				self.files['Source'].append(incfile)
			else:
				self.dependencies['Source'].append(incfile)

	# Compile plugin if missing our out of date, default to disabled
	def compile_plugin(self):
		print("Compiling %s" % self.name)
		os.system("%s %s -o%s -e%s" % (getpath("scripting/spcomp"), self.sp_file, self.smx_file, getpath("scripting/output/%s.out" % self.name)))
		return os.path.isfile(self.smx_file)

	def process_plugin(self):
		if not os.path.isfile(self.smx_file) or self.compile:
			self.compile_plugin()
		with open(self.smx_file, 'rb') as fp:
			try:
				self.plugin = smx.SourcePawnPlugin(fp)
				self.files['Plugin'].append("plugins/%s" % os.path.basename(self.smx_file))
			except:
				print("Could not load \"%s\"!" % self.smx_file)
				return
		self.myinfo = self.plugin.myinfo

	def create_updater_file(self):
		fp = open(getpath("updater-data/update-%s.txt" % self.name), 'w')
		tmpl = str(Template ( file = "templates/update.tmpl", searchList = [{ 'plugin': self }] ))
		fp.write(tmpl)
		fp.close()
		return

	def create_plugin_file(self):
		fp = open(getpath("doc/%s.md" % self.name), 'w')
		tmpl = str(Template ( file = "templates/plugin.tmpl", searchList = [{ 'plugin': self }] ))
		fp.write(tmpl)
		fp.close()
		return

if __name__ == "__main__":
	main()
