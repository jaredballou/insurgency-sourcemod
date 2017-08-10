#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Game data extraction library

This library has tools to extract game data files from an installed game to the
format needed for inclusion in insurgency-data mods format. It supports version
separation, extracting files from VPK or filesystem, and is managed via the
config.yaml file.
"""
import os
from pprint import pprint
import sys
from vdf.theater import Theater
import vdf

def main():
	gf = GameFile()
	sf = ScriptFile(gamefile=gf)

"""
def dict_recurse(obj):
	for v in getattr(obj, _iter_values)():
		if isinstance(v, VDFDict) and v.has_duplicates():
			return True
		elif isinstance(v, dict):
			return dict_recurse(v)
	return False

return dict_recurse(self)

        def dict_recurse(obj):
            for v in getattr(obj, _iter_values)():
                if isinstance(v, VDFDict) and v.has_duplicates():
                    return True
                elif isinstance(v, dict):
                    return dict_recurse(v)
            return False

        return dict_recurse(self)
	"player_hurt"
	{
		"priority" "short"
		"attacker" "short"
		"dmg_health" "short"
		"health" "byte"
		"damagebits" "long"
		"hitgroup" "short"
		"weapon" "string"
		"weaponid" "short"
		"userid" "short"
	}
	"grenade_detonate"
	{
		"userid" "short"
		"effectedEnemies" "short"
		"y" "float"
		"x" "float"
		"entityid" "long"
		"z" "float"
		"id" "short"
	}
"""

class GameFile(object):
	def __init__(self, file=None):
		if file is None:
			file = "modevents.res"
		self.file = file
		self.events = {}

		self.data = self.load_file(file, 1)
		self.process_events()

	def load_file(self, file=None, striplevels=0):
		if file is None:
			file = self.file
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

	def process_events(self):
		for event, fields in self.data.iteritems():
			self.add_event(event, fields)

	def add_event(self, event, fields):
		self.events[event] = {}
		for field, type in fields.iteritems():
			self.events[event][field] = type
# = GameEvent(name=event, fields=fields)


class ScriptFile(object):
	"""
//   none   : value is not networked
//   string : a zero terminated string
//   bool   : unsigned int, 1 bit
//   byte   : unsigned int, 8 bit
//   short  : signed int, 16 bit
//   long   : signed int, 32 bit
//   float  : float, 32 bit
	"""
	def __init__(self, gamefile):
		self.hooks = []
		self.functions = []
		self.load_gamefile(gamefile)
		self.process_events()
		print("\n".join(self.hooks))
		print("\n\n".join(self.functions))

	def load_gamefile(self, gamefile):
		self.gamefile = gamefile

	def process_event(self, event, fields):
		self.hooks.append(self.process_event_hook(event, fields))
		self.functions.append(self.process_event_function(event, fields))

	def process_events(self):
		for event, fields in self.gamefile.data.iteritems():
			self.process_event(event, fields)

	def camelcase(self, str):
		return ''.join(x for x in str.replace("_", " ").title() if not x.isspace())

	def process_event_hook(self, event, fields):
		return """HookEvent("{}", Event_{});""".format(event, self.camelcase(event))

	def getvarname(self, field, type):
		return "m_{}{}".format(type[0], self.camelcase(field))

	def process_event_function(self, event, fields):
		defs = []
		gets = []

		fstr = ["public Action:Event_{}(Handle:event, const String:name[], bool:dontBroadcast) {{\n".format(self.camelcase(event))]
		for field, type in fields.iteritems():
			if type in ["byte", "short"]:
				type = "int"
			varname = self.getvarname(field, type)
			if type in ["string"]:
				fstr.append("""\tdecl String:{}[256];""".format(varname))
				fstr.append("""\tGetEventString(event, "{}", {}, sizeof({}));""".format(field, varname, varname))
			else:
				fstr.append("""\t{} {} = GetEvent{}(event, "{}");""".format(type, varname, type.title(), field))
		fstr.append("\treturn Plugin_Continue;")
		fstr.append("}")
		fs = "\n".join(fstr)
		return fs

class ResFile(object):
	def __init__(self, file=None):
		if file is None:
			file = "modevents.res"
		self.file = file
		self.hooks = []
		self.functions = []
		self.data = self.load_file(file, 1)
		self.process_events()
		print("\n".join(self.hooks))
		print("\n\n".join(self.functions))

	def load_file(self, file=None, striplevels=0):
		if file is None:
			file = self.file
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

	def process_events(self):
		for event, fields in self.data.iteritems():
			self.process_event(event, fields)


	def camelcase(self, str):
		return ''.join(x for x in str.replace("_", " ").title() if not x.isspace())

	def process_event(self, event, fields):
		self.hooks.append(self.process_event_hook(event, fields))
		self.functions.append(self.process_event_function(event, fields))

	def process_event_hook(self, event, fields):
		return """HookEvent("{}", Event_{});""".format(event, self.camelcase(event))

	def getvarname(self, field, type):
		return "m_{}{}".format(type[0], self.camelcase(field))

	def process_event_function(self, event, fields):
		defs = []
		gets = []

		fstr = ["public Action:Event_{}(Handle:event, const String:name[], bool:dontBroadcast) {{\n".format(self.camelcase(event))]
		for field, type in fields.iteritems():
			if type in ["byte", "short"]:
				type = "int"
			varname = self.getvarname(field, type)
			if type in ["string"]:
				fstr.append("""\tdecl String:{}[256];""".format(varname))
				fstr.append("""\tGetEventString(event, "{}", {}, sizeof({}));""".format(field, varname, varname))
			else:
				fstr.append("""\t{} {} = GetEvent{}(event, "{}");""".format(type, varname, type.title(), field))
		fstr.append("\treturn Plugin_Continue;")
		fstr.append("}")
		fs = "\n".join(fstr)
		return fs

if __name__ == "__main__":
	main()
