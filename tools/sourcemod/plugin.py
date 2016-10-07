from Cheetah.Template import Template
from collections import defaultdict, OrderedDict
import csv
from glob import glob
import os
from pprint import pprint
import logging
import re
import shlex
import smx
import subprocess
import sys
import vdf

class SourceModPlugin(object):

    def __init__(self, name, parent, config=None, write_doc=False, write_updater=True, run=False, compile=True):
        self.parent = parent
        self.name = name
        logging.info("Processing %s" % self.name)
        #if self.parent.plugins_write_doc:
        #if self.parent.plugins_write_updater:
        #if self.parent.plugins_compile:
        #if self.parent.plugins_run:

        self.config = config
        self.defines = {}
        self.cvars = {}
        self.dependencies = []
        self.commands = {}
        self.todo = {}
        self.files = {"Plugin": [], "Source": []}
        self.compile = False
        self.myinfo = {}
        self.todos = {}
        self.updater = defaultdict(lambda: defaultdict(vdf.VDFDict))

        self.get_files()

        self.process_plugin_source()

        self.process_plugin_smx()

        if 'run' in self.config and self.config['run']:
            self.run_plugin()

        self.create_plugin_doc()
        if (write_doc):
            self.write_plugin_doc()

        self.create_plugin_updater()
        if (write_updater):
            self.write_plugin_updater()

    def get_files(self):
        """Get values from plugin"""
        sp_file = self.parent.getpath(["scripting", "%s.sp" % self.name])
        if not os.path.isfile(sp_file):
            logging.error("Cannot find plugin source file \"%s\"!" % sp_file)
            return dict()
        smx_file = self.parent.getpath(["plugins", "%s.smx" % self.name])
        if not os.path.isfile(smx_file) or os.stat(sp_file).st_mtime > os.stat(smx_file).st_mtime:
            self.compile = True
        self.sp_file = sp_file
        self.smx_file = smx_file

    def process_plugin_source(self):
        self.read_plugin_source()
        self.parse_plugin_source_defines()
        self.parse_plugin_source_dependencies()
        self.parse_plugin_source_functions()
        self.parse_plugin_source_includes()

    def read_plugin_source(self):
        with open(self.sp_file, 'r') as stream:
            try:
                self.source = stream.read()
                self.add_file(file="scripting/%s" % os.path.basename(self.sp_file), type='Source')
            except:
                logging.error("Could not load \"%s\"!" % self.sp_file)
                return

    def parse_plugin_source_dependencies(self):
        """Find all dependencies. Use comments for now"""
        for dependencies in re.findall(r"\/\/Depends:(.*)", self.source):
            for dep in dependencies.split():
                if not dep in self.dependencies:
                    self.dependencies.append(dep)

    def parse_plugin_source_defines(self):
        """Find all #define values"""
        for define in re.findall(r".*#define[\t ]*([^\s]*)[\t ]*([^\r\n]*)", self.source):
            self.defines[define[0]] = define[1].strip("""'" \t""")

    def interpolate(self, data):
        """Interpolate #define values"""
        if data in self.defines.keys():
            return self.defines[data]
        else:
            return data

    def parse_plugin_source_functions(self):
        sp = self.parent.config['source_parser']
        for func_type in sp['functions'].keys():
            for func_name in sp['functions'][func_type].keys():
                for func in re.findall(r"(%s)\s*\((.*)\);" % func_name, self.source):
                    parts = [re.sub(r",$","",w).strip("""'" \t""") for w in shlex.split(func[1])]

                    if func_type == 'cvars':
                        if parts[0].endswith('_version'):
                            continue
                        self.cvars[parts[0]] = {'value': self.interpolate(parts[1]), 'description': self.interpolate(parts[2])}
                    elif func_type == 'commands':
                        self.commands[parts[0]] = {'function': parts[1]}
                        desc_idx = 2 + (func[0] == 'RegAdminCmd')
                        if len(parts) > desc_idx:
                            self.commands[parts[0]]["description"] = parts[desc_idx]
                    else:
                        self.add_file(file="%s/%s.txt" % (func_type, parts[0]))

                            
    def add_file(self, file, type='Plugin'):
        if not type in self.files.keys():
            type = 'Plugin'
        if not file in self.files[type]:
            self.files[type].append(file)

    def parse_plugin_source_includes(self):
        for include in re.findall(r"#include[\t ]*<([^>]+)>", self.source):
            incfile = "scripting/include/%s.inc" % include
            if include in self.parent.config['libraries']['stock'] or include in self.parent.config['libraries']['thirdparty'] or incfile in self.files['Source']:
                continue
            self.add_file(file=incfile, type='Source')

    def compile_plugin(self):
        """Compile plugin if missing our out of date, default to disabled"""
        print("Compiling %s" % self.name)
        cmd = [self.parent.compiler_path, self.sp_file, "-o", self.smx_file]
        logging.debug(cmd)
        result = subprocess.check_output(cmd)
        print(result)
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
                self.add_file(file="plugins/%s" % os.path.basename(self.smx_file))
                self.plugin = smx.SourcePawnPlugin(fp)
            except:
                logging.error("Could not load \"%s\"!" % self.smx_file)
                return

    def run_plugin(self):
        """Run the plugin using the PySMX interpreter"""
        print("***RUNNING PLUGIN***")
        self.plugin.run()

    def create_plugin_updater(self):
        self.updater = defaultdict(lambda: defaultdict(vdf.VDFDict))
        self.updater["Updater"]["Information"]["Version"]["Latest"] = self.myinfo["version"]
        for key in ["name", "description"]:
            if key in self.myinfo.keys():
                self.updater["Updater"]["Information"]["Notes"] = self.myinfo[key]
        for section in ["Plugin", "Source"]:
            for file in self.files[section]:
                self.updater["Updater"]["Files"][section] = file

    def write_plugin_updater(self,filename=None):
        self.create_plugin_updater()
        data = vdf.dumps(self.updater, pretty=True)
        if filename is None:
            filename = self.parent.getpath(["updater-data", "update-%s.txt" % self.name])
        self.parent.write_file(filename=filename,data=data)

    def create_plugin_doc(self):
        self.readme = str(Template ( file = self.parent.getpath(["tools", "templates", "plugin.tmpl"]), searchList = [{ 'plugin': self }] ))

    def write_plugin_doc(self,filename=None):
        self.create_plugin_doc()
        if filename is None:
            filename = self.parent.getpath(["doc", "%s.md" % self.name])
        self.parent.write_file(filename=filename,data=self.readme)
