import os
import sys
import re
from pprint import pprint
from collections import defaultdict, OrderedDict
from glob import glob
from Cheetah.Template import Template
sys.path.append(os.path.join(os.getcwd(),"pysmx"))
import smx

class SourceModPlugin(object):

	def __init__(self,name=None,config=None,parent=None,write_readme=False,write_updater=True):
		self.config = config
		self.cvars = {}
		self.commands = {}
		self.todo = {}
		self.files = {"Plugin": [], "Source": []}
		self.dependencies = {"Plugin": [], "Source": []}
		self.compile = False
		self.myinfo = {}
		self.todos = {}
		if not parent is None:
			self.parent = parent
		if not name is None:
			self.name = name
		else:
			self.name = "UNKNOWN"

		self.get_files()
		self.process_plugin_source()
		self.process_plugin_smx()

		self.create_plugin_readme()
		if (write_readme):
			self.write_plugin_readme()

		self.create_plugin_updater()
		if (write_updater):
			self.write_plugin_updater()

	# Get values from plugin
	def get_files(self):
		sp_file = self.parent.getpath("scripting/%s.sp" % self.name)
		if not os.path.isfile(sp_file):
			print("ERROR: Cannot find plugin source file \"%s\"!" % sp_file)
			return dict()
		smx_file = self.parent.getpath("plugins/%s.smx" % self.name)
		if not os.path.isfile(smx_file) or os.stat(sp_file).st_mtime > os.stat(smx_file).st_mtime:
			self.compile = True
		self.sp_file = sp_file
		self.smx_file = smx_file

	def process_plugin_source(self):
		self.read_plugin_source()
		self.parse_plugin_source_functions()
		self.parse_plugin_source_includes()

	def read_plugin_source(self):
		with open(self.sp_file, 'r') as stream:
			try:
				self.source = stream.read()
				self.files['Source'].append("scripting/%s" % os.path.basename(self.sp_file))
			except:
				print("Could not load \"%s\"!" % self.sp_file)
				return

	def parse_plugin_source_functions(self):
		sp = self.parent.config['source_parser']
		for func_type in sp['functions'].keys():
			for func_name in sp['functions'][func_type].keys():
				for func in re.findall(r"(%s)\s*\((.*)\);" % func_name, self.source):
					parts = [p.strip("""'" \t""") for p in func[1].split(',')]
					if func_type == 'cvars':
						if parts[0].endswith('_version'):
							continue
						self.cvars[parts[0]] = {'value': parts[1], 'description': parts[2]}
					elif func_type == 'commands':
						self.commands[parts[0]] = {'function': parts[1]}
						desc_idx = 2 + (func[0] == 'RegAdminCmd')
						if len(parts) > desc_idx:
							self.commands[parts[0]]["description"] = parts[desc_idx]
					else:
						file = "%s/%s.txt" % (func_type, parts[0])
						if not file in self.files['Plugin']:
							self.dependencies['Plugin'].append(file)

	def parse_plugin_source_includes(self):
		for include in re.findall(r"#include[\t ]*<([^>]+)>", self.source):
			incfile = "scripting/include/%s.inc" % include
			if include in self.config['libraries']['stock'] or include in self.config['libraries']['thirdparty'] or incfile in self.files['Source']:
				continue
			if include == self.name:
				self.files['Source'].append(incfile)
			else:
				self.dependencies['Source'].append(incfile)

	# Compile plugin if missing our out of date, default to disabled
	def compile_plugin(self):
		print("Compiling %s" % self.name)
		os.system("%s %s -o%s -e%s" % (self.parent.getpath("scripting/spcomp"), self.sp_file, self.smx_file, self.parent.getpath("scripting/output/%s.out" % self.name)))
		return os.path.isfile(self.smx_file)

	def process_plugin_smx(self):
		if not os.path.isfile(self.smx_file) or self.compile:
			self.compile_plugin()
		self.read_plugin_smx()
		try:
			for prefix in self.parent.config['settings']['prefixes']:
				if self.plugin.myinfo['name'].startswith(prefix):
					self.plugin.myinfo['name'] = self.plugin.myinfo['name'][len(prefix):].strip()
		except:
			pass
		self.myinfo = self.plugin.myinfo
	def read_plugin_smx(self):
		with open(self.smx_file, 'rb') as fp:
			try:
				self.plugin = smx.SourcePawnPlugin(fp)
				self.files['Plugin'].append("plugins/%s" % os.path.basename(self.smx_file))
			except:
				print("Could not load \"%s\"!" % self.smx_file)
				return

	def create_plugin_updater(self):
		self.updater = str(Template ( file = self.parent.getpath("tools/templates/update.tmpl"), searchList = [{ 'plugin': self, 'config': self.parent.interpolate(data=self.parent.config) }] ))

	def write_plugin_updater(self,filename=None):
		self.create_plugin_updater()
		if filename is None:
			filename = self.parent.getpath("updater-data/update-%s.txt" % self.name)
		self.parent.write_file(filename=filename,data=self.updater)

	def create_plugin_readme(self):
		self.readme = str(Template ( file = self.parent.getpath("tools/templates/plugin.tmpl"), searchList = [{ 'plugin': self }] ))

	def write_plugin_readme(self,filename=None):
		self.create_plugin_readme()
		if filename is None:
			filename = self.parent.getpath("doc/%s.md" % self.name)
		self.parent.write_file(filename=filename,data=self.readme)
