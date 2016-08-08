import os
import sys
import yaml
import re

from pprint import pprint
from collections import defaultdict, OrderedDict
from glob import glob
from Cheetah.Template import Template
from plugin import *

sm_dirs = ("bin", "configs", "data", "extensions", "gamedata", "logs", "plugins", "scripting", "translations")

class SourceMod(object):
	plugins = {}
	def __init__(self,config_file=None,root=None):
		self.find_root(path=root)
		self.load_config(config_file=config_file)
		self.load_files()
		self.load_plugins()

	def find_root(self,path=None):
		if path is None:
			path = os.path.realpath(__file__)
		root = os.path.dirname(path)
		for dir in sm_dirs:
			if not os.path.isdir(os.path.join(root,dir)):
				if root != "/":
					self.find_root(path=root)
				else:
					print("ERROR: Cannot find SourceMod directory!")
				return
		self.root = root

	def load_files(self):
		self.files = {}
		for ft in self.config['files'].keys():
			pr = "%s/" % self.getpath(self.config['files'][ft]['path'])
			pe = ".%s" % self.config['files'][ft]['ext']
			self.files[ft] = [y.replace(pr,"").replace(pe,"") for x in os.walk(pr) for y in glob(os.path.join(x[0], "*%s" % pe))]

	def load_config(self,config_file=None):
		if config_file is None:
			config_file = self.getpath("tools/config.yaml")
		self.config_file = config_file
		self.config = self.get_yaml_file(self.config_file)

	def load_plugins(self):
		for name in self.config['plugins']['build']:
			self.load_plugin(name)
		for name in self.config['plugins']['disabled']:
			if os.path.isfile(self.getpath("plugins/%s.smx" % name)):
				print "need to disable %s.smx" % name
			if os.path.isfile(self.getpath("scripting/%s.sp" % name)):
				print "need to disable %s.sp" % name

	def load_plugin(self,name):
		if name in self.plugins.keys():
			pass
		else:
			self.plugins[name] = SourceModPlugin(name=name,config=self.config,parent=self)
			#self.plugins[name].plugin.run()

	def getpath(self,path=""):
		return os.path.join(self.root,path)

	def get_yaml_file(self,yaml_file):
		with open(yaml_file, 'r') as stream:
			try:
				return(yaml.load(stream))
			except yaml.YAMLError as exc:
				print(exc)
				sys.exit()

	def create_readme(self):
		self.readme = str(Template ( file = self.getpath("tools/templates/readme.tmpl"), searchList = [{ 'plugins': self.plugins, 'sortedKeys': sorted(self.plugins.keys()) }] ))

	def write_readme(self,filename=None):
		if filename is None:
			filename = self.getpath("README.md")
		self.create_readme()
		self.write_file(filename=filename,data=self.readme)

	def write_file(self,filename,data):
		fp = open(filename, 'w')
		fp.write(data)
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
		if kt in [int]:
			return val
		if kt in [str]:
			val = item
	 		try:
				while (val.find('%(') != -1):
					val = (val) % data
					val = (val) % interpolate_data
			except:
				pass
		if kt in [list,set,tuple]:
			val = []
			for li in item:
				val.append(self.interpolate(data=li,interpolate_data=interpolate_data))
		if kt in [OrderedDict,dict]:
			val = dict()
			for skey in item.keys():
				val[skey] = self.interpolate(key=skey,data=item,interpolate_data=interpolate_data)
		return val
