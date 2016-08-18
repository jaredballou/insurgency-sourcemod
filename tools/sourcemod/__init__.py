import argparse
from Cheetah.Template import Template
from collections import defaultdict, OrderedDict
from glob import glob
import logging
import os
import platform
from plugin import *
from pprint import pprint
import re
import sys
import types
import yaml

# Directories that need to be present in the SourceMod root
sm_dirs = ("bin", "configs", "data", "extensions", "gamedata", "logs", "plugins", "scripting", "translations")

class SourceMod(object):
    """Main object that manages a SourceMod installation
        Attributes:
    """
    plugins = {}
    def __init__(self, config_file=None, root=None, plugins_write_doc=False, write_readme=True, plugins_write_updater=True, plugins_compile=True, plugins_run=False):
        self.platform = platform.system().lower()
        if self.platform == "windows":
            self.compiler_file = "spcomp.exe"
        else:
            self.compiler_file = "spcomp"
        self.plugins_write_doc = plugins_write_doc
        self.write_readme = write_readme
        self.plugins_write_updater = plugins_write_updater
        self.plugins_compile = plugins_compile
        self.plugins_run = plugins_run
        self.find_root(path=root)
        self.load_config(config_file=config_file)
        self.load_file_types()
        self.compiler_path = self.getpath(["scripting",self.compiler_file])
        self.load_plugins()
        if write_readme:
            self.create_readme()

    def find_root(self,path=None):
        if path is None:
            path = os.path.realpath(__file__)
        root = os.path.dirname(path)
        for dir in sm_dirs:
            if not os.path.isdir(os.path.join(root,dir)):
                if root != os.path.dirname(root):
                    self.find_root(path=root)
                else:
                    logging.error("Cannot find SourceMod directory!")
                return
        self.root = root

    def get_config(self, key, default=None):
        """Get a value from the config hash, if available"""

    def load_file_types(self):
        self.files = {}
        for ft in self.config['file_types'].keys():
            pr = self.getpath(self.config['file_types'][ft]['path']) + os.sep
            pe = ".%s" % self.config['file_types'][ft]['ext']
            self.files[ft] = [y.replace(pr,"").replace(pe,"") for x in os.walk(pr) for y in glob(os.path.join(x[0], "*%s" % pe))]

    def load_config(self,config_file=None):
        if config_file is None:
            config_file = self.getpath(["tools", "config.yaml"])
        self.config_file = config_file
        self.config = self.get_yaml_file(self.config_file)

    def load_plugins(self):
        for name, config in self.config['plugins']['build'].iteritems():
            self.load_plugin(name=name, config=config)
        for name in self.config['plugins']['disabled']:
            if os.path.isfile(self.getpath(["plugins", "%s.smx" % name])):
                logging.warning("need to disable %s.smx" % name)
            if os.path.isfile(self.getpath(["scripting", "%s.sp" % name])):
                logging.warning("need to disable %s.sp" % name)

    def load_plugin(self, name, config=None):
        if name in self.plugins.keys():
            logging.warning("Plugin %s already processed!" % name)
        else:
            self.plugins[name] = SourceModPlugin(name=name, config=config, parent=self)

    def getpath(self,path=""):
        if isinstance(path, types.StringTypes):
            pass
        else:
            path = os.sep.join(path)
        return os.path.join(self.root,path)

    def get_yaml_file(self,yaml_file):
        with open(yaml_file, 'r') as stream:
            try:
                return(yaml.load(stream))
            except yaml.YAMLError as exc:
                logging.error(exc)
                sys.exit()

    def create_readme(self,filename=None):
        if filename is None:
            filename = self.getpath("README.md")
        self.readme = str(Template ( file = self.getpath(["tools", "templates", "readme.tmpl"]), searchList = [{ 'plugins': self.plugins, 'sortedKeys': sorted(self.plugins.keys()) }] ))
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
