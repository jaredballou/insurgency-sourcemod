# -*- coding: utf-8 -*-
"""Game data extraction library

This library has tools to extract game data files from an installed game to the
format needed for inclusion in insurgency-data mods format. It supports version
separation, extracting files from VPK or filesystem, and is managed via the
config.yaml file.
"""
import configparser
from fnmatch import fnmatch
from glob import glob
import hashlib
import json
import os
import re
from shutil import copyfile
import subprocess
import sys
import vpk
from vdf.theater import Theater
import vdf
import yaml

regex_float = r'[\.\deE\+\-]+'
regex_vertex = r'(' + regex_float + r')\s*(' + regex_float + r')\s*(' + regex_float + r')'
regex_plane = r'\(' + regex_vertex + r'\)'

class Vertex(object):
	def __init__(self, x=0, y=0, z=0):
		if type(x) == Vertex:
			y = x.y
			z = x.z
			x = x.x
		elif type(x) == str:
			d = re.findall(regex_vertex, x)
			if len(d) == 3:
				x, y, z = d
			else:
				return
		elif type(x) in [list, tuple, set]:
			x, y, z = x
		self.x = float(x)
		self.y = float(y)
		self.z = float(z)

	def __repr__(self):
		return '%s %s %s' % (self.x, self.y, self.z)

class Plane:
	"""A set of three Vertices which define a plane."""
	def __init__(self, v0=Vertex(), v1=Vertex(), v2=Vertex()):
		"""Create a new Vertex representing the position (x, y, z)."""
		if type(v0) == str:
			# If we got a string, split it into three vertices
			d = re.findall(regex_plane, v0)
			#r'\(([\.\deE\+\-]+)\s*([\.\deE\+\-]+)\s*([\.\deE\+\-]+)\)'
			if len(d) == 3:
				v0 = Vertex(d[0])
				v1 = Vertex(d[1])
				v2 = Vertex(d[2])
			else:
				return
		self.v0 = Vertex(v0)
		self.v1 = Vertex(v1)
		self.v2 = Vertex(v2)

	def __repr__(self):
		return '(%s) (%s) (%s)' % (self.v0, self.v1, self.v2)

class Entity(object):
	"""An entity on the map"""
	propdefs = {}
	def __init__(self, classname=None, entity=None):
		self.min = None
		self.max = None
		if entity is not None:
			self.parse_entity(entity=entity)
		else:
			self.entity = vdf.VDFDict()
			if classname is not None:
				self.classname = classname

	def parse_entity(self, entity):
		"""Parse an entity dict into this object"""
		self.entity = entity
		for prop, propconf in self.propdefs.iteritems():
			if prop in entity:
				setattr(self, prop, entity[prop])
			else:
				setattr(self, prop, None)
		if "solid" in entity:
			self.parse_solid()

	def parse_solid(self, entity=None):
		"""Parse my own solid"""
		if entity is None:
			entity = self.entity
		for name, side in entity["solid"].iteritems():
			if name != "side":
				continue
			p = Plane(side["plane"])
			for v in ["v0", "v1", "v2"]:
				vertex = getattr(p, v)
				if self.min is None:
					self.min = Vertex(vertex)
				if self.max is None:
					self.max = Vertex(vertex)
				for axis in ["x", "y", "z"]:
					val = getattr(vertex, axis)
					min = getattr(self.min, axis)
					max = getattr(self.max, axis)
					if val > max:
						setattr(self.max, axis, val)
					if val < min:
						setattr(self.min, axis, val)

	def load_propdefs(self, propdefs):
		"""Load property definitions into global object settings"""
		self.propdefs = propdefs.copy()
"""
	def __repr__(self):
		return vars(self)
		# TODO: Represent as '"<id>" { "<field>" "<val>".... }'
		'"{}" "{}"'.format(for prop, propconf in self.propdefs.iteritems()
			if prop in self:
				setattr(self, prop, entity[prop])
			else:
				setattr(self, prop, None)
		return '(%s) (%s) (%s)' % (self.v0, self.v1, self.v2)
"""
class MapFile(object):
	def __init__(self, name, parent, type=None, path=None, match=None, filename=None, checksum=None, content=None):
		self.name = name
		self.parent = parent
		self.type = type
		self.path = path
		self.match = match
		self.filename = filename
		self.checksum = checksum
		self.content = content

class Map(object):
	"""Object that handles BSP, NAV, and TXT (CPSetup) files in /maps/ directory. Also manages /resource/overviews/%(map).txt overview settings.
		Attributes:
			parent (Game): 
			 (): 
			 (): 
			 (): 
			 (): 
	"""
	mapdata_version = 1
	def __init__(self, parent, name, bsp=None, nav=None, cpsetup_txt=None, overview_txt=None, overview_vtf=None, parsed_file=None, vmf_file=None, do_parse=True, decompile=True, unpack_files=True):
		"""
			Args:
		"""
		self.parent = parent
		self.name = name
		print("Checking map '{}'".format(name))
		# Load propdefs into Entity object
		Entity().load_propdefs(propdefs=self.parent.parent.config['map_entities_props'])
		self.map = vdf.VDFDict()
		self.map_files = {}
		self.map_files_checksums = {}
		self.map_files_paths = {}
		self.map_files_data = vdf.VDFDict()
		self.entities = []
		self.do_parse = do_parse
		self.decompile = decompile
		self.unpack_files = unpack_files
		self.find_map_files()
		self.parse_json()
		self.parse_map_files()
		self.export_parsed()

	def md5Checksum(self, filename):
		if not os.path.exists(filename):
			return None
		with open(filename, 'rb') as fh:
			m = hashlib.md5()
			while True:
				data = fh.read(8192)
				if not data:
					break
				m.update(data)
			return m.hexdigest()

	def find_map_files(self):
		"""Find the source files, if they exist"""
		for file_type, file_conf in self.parent.parent.config['map_files'].iteritems():
			if "root" in file_conf:
				file_root = file_conf["root"]
			else:
				file_root = self.parent.extract_root
			file_path = os.path.join(file_conf["path"] % vars(self), file_conf["match"]% vars(self))
			self.map_files[file_type] = self.parent.find_file(file=file_path, default=None)
			if self.map_files[file_type] is not None:
				self.map_files_checksums[file_type] = self.md5Checksum(filename=self.map_files[file_type])
			self.map_files_paths[file_type] = os.path.join(file_root, file_path)
			#self.source_files[file_type] = 

	def load_keyvalues(self, file=None, striplevels=0):
		"""Load file as KeyValues.
			Args:
				file (str): Filename to load
				striplevels (int): How many levels to strip off. This will get the first element of the result, so it's good for stripping "theater" and "cpsetup.txt" from single-section files.
			Returns:
				dict of result
		"""
		if not os.path.exists(file):
			print("Cannot find '{}'".format(file))
			return None
		data = Theater(filename=file).processed
		for x in range(0, striplevels):
			iv = data.itervalues()
			while True:
				next = iv.next()
				if next is None:
					return {}
				if isinstance(next, vdf.VDFDict):
					data = next
					break
		return data

	def dump_vdf(self, data):
		"""Dump VDF content to console."""
		print(vdf.dumps(data, pretty=True))

	def parse_map_files(self):
		"""Iterate through all configured file types, and process them"""
		for type,file in self.map_files.iteritems():
			if file is None:
				continue
			if not self.file_needs_parsing(type):
				continue
			print("Parsing {}".format(type))
			getattr(self, "parse_{}".format(type))()
			self.find_map_files()

	def file_needs_parsing(self, type):
		"""Determine if a file type needs to be processed"""
		# TODO: Support output type skipping
		if not "json" in self.map_files_data:
			return True
		if not "map_files_checksums" in self.map_files_data["json"]:
			return True
		if not type in self.map_files_checksums:
			return True
		if not type in self.map_files_data["json"]["map_files_checksums"]:
			return True
		if self.map_files_data["json"]["map_files_checksums"][type] != self.map_files_checksums[type]:
			return True
		if not "mapdata_version" in self.map_files_data["json"]:
			return True
		if self.map_files_data["json"]["mapdata_version"] != self.mapdata_version:
			return True
		return False

	def parse_bsp(self, force=False):
		"""Decompile BSP file to VMF"""
		if not force and "vmf" in self.map_files and self.map_files["vmf"] is not None and os.path.exists(self.map_files["vmf"]):
			return False
		self.decompile_bsp()
		self.extract_bsp()

	def parse_vmf(self):
		"""Parse decompiled BSP contents"""
		self.map_files_data["vmf"] = self.load_keyvalues(file=self.map_files["vmf"])
		for type, entity in self.map_files_data["vmf"].iteritems():
			if type != "entity":
				continue
			if not "classname" in entity:
				continue
			if not entity['classname'] in self.parent.parent.config["map_entities"]:
				continue
			self.entities.append(Entity(entity=entity))

	def parse_nav(self):
		"""Parse NAV file and export JSON object with relevant data"""
		pass

	def parse_cpsetup_txt(self):
		"""Process cpsetup.txt file"""
		self.map_files_data["cpsetup_txt"] = self.load_keyvalues(file=self.map_files["cpsetup_txt"], striplevels=1)

	def parse_overview_txt(self):
		"""Process Overview text file"""
		self.map_files_data["overview_txt"] = self.load_keyvalues(file=self.map_files["overview_txt"], striplevels=1)

	def parse_overview_vmt(self):
		pass

	def parse_overview_vtf(self):
		pass

	def parse_overview_png(self):
		pass

	def extract_bsp(self):
		"""Use PakRat to extract the ZIP file of assets inside BSP."""
		pass

	def decompile_bsp(self):
		"""Decompile the BSP file to VMF."""
		try:
			print("Decompiling %s..." % self.name)
			vmf_dir = os.path.dirname(self.map_files_paths["vmf"])
			if not os.path.exists(vmf_dir):
				os.makedirs(vmf_dir)
			bspsrc_args = ['-no_areaportals', '-no_cubemaps', '-no_details', '-no_occluders', '-no_overlays', '-no_rotfix', '-no_sprp', '-no_brushes', '-no_cams', '-no_lumpfiles', '-no_prot', '-no_visgroups']
			bspsrc_cmd = ['java', '-cp', self.parent.parent.config['tools']['bspsrc'], 'info.ata4.bspsrc.cli.BspSourceCli'] + bspsrc_args + [self.map_files["bsp"], '-o', self.map_files_paths["vmf"]]
			process = subprocess.Popen(bspsrc_cmd, stdout=subprocess.PIPE)
			out, err = process.communicate()
			print("Done")
		except:
			print("Failed")

	def parse_json(self):
		"""Load existing parsed JSON file, if it exists"""
		if not os.path.exists(self.map_files_paths["json"]):
			return
		try:
			with open(self.map_files_paths["json"]) as data_file:
				self.map_files_data["json"] = json.load(data_file)
		except:
			self.map_files_data["json"] = {}

	def export_parsed(self):
		"""Export all parsed data to single JSON file for all map objects."""
		mapdata = {
			'mapdata_version': self.mapdata_version,
			'map_files_checksums': self.map_files_checksums,
			'map': self.map,
		}
		for file in ["overview_txt", "cpsetup_txt"]:
			if file in self.map_files_data:
				mapdata[file] = self.map_files_data[file]
			else:
				mapdata[file] = {"missing": True}
		self.create_path(self.map_files_paths["json"])
		with open(self.map_files_paths["json"], "w") as outfile:
			json.dump(mapdata, outfile, indent=4)

	def create_path(self, filename):
		"""Create directory tree needed for this file"""
		dirname = os.path.dirname(filename)
		if not os.path.exists(dirname):
			print("Creating {}".format(dirname))
			os.makedirs(dirname)
"""
		BASENAME=$(basename "${MAP}" .bsp)
		SRCFILE="${DATADIR}/maps/src/${BASENAME}_d.vmf"
		ZIPFILE="${MAP}.zip"
		if [ "${SRCFILE}" -ot "${MAP}" ]; then
			echo ">> Decompile ${MAP} to ${SRCFILE}"
			add_manifest_md5 "${SRCFILE}"
		fi
		# Check if the map even needs to be unzipped/extracted
BSPSRC="java -cp ${REPODIR}/thirdparty/bspsrc/bspsrc.jar
# Pakrat command
PAKRAT="java -jar ${REPODIR}/thirdparty/pakrat/pakrat.jar"
			$BSPSRC "${MAP}" -o "${SRCFILE}"

		PAKLIST="${DATADIR}/maps/paklist/${BASENAME}.txt"
		if [ "${PAKLIST}" -ot "${MAP}" ]; then
			$PAKRAT -list "${MAP}" > "${PAKLIST}"
		fi
		MAPSRCLIST=$(egrep -i "${MAPSRCDIRS_EGREP}" "${PAKLIST}" | awk '{print $1}')
		if [ "${MAPSRCLIST}" == "" ]; then continue; fi
		DOUNZIP=0
		if [ "${ZIPFILE}" -ot "${MAP}" ]; then DOUNZIP=1; fi
		# If we are missing resources, unzip
		for SRCTEST in $MAPSRCLIST; do
			if [ ! -e "${DATADIR}/${SRCTEST}" ]; then DOUNZIP=1; fi
		done
		if [ "${DOUNZIP}" == "1" ]; then
			echo ">> Extract files from ${MAP} to ${ZIPFILE}"
			$PAKRAT -dump "${MAP}"
			echo ">> Extracting map files from ZIP"
			unzip -o "${ZIPFILE}" -d "${DATADIR}/" $MAPSRCLIST 2>/dev/null
		fi
"""
