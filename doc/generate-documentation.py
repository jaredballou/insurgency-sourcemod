#!/usr/bin/env python
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

import os, sys, yaml, pprint, re
from keyvalues import KeyValues
sys.path.append("pysmx")
import smx
# Set variables

# Paths
cwd = os.getcwd()
root = os.path.dirname(cwd)
paths = {
	'doc':		cwd,
	'tmp':		os.path.join(cwd,"tmp"),
	'include':	os.path.join(cwd,"include"),
	'root':		root,
	'plugins':	os.path.join(root,"plugins"),
	'scripting':	os.path.join(root,"scripting"),
	'libraries':	os.path.join(root,"scripting","include"),
	'gamedata':	os.path.join(root,"gamedata"),
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
	'plugins':	os.path.join(paths['doc'],"plugins.yaml"),
	'libraries':	os.path.join(paths['doc'],"libraries.yaml"),
	'readme':	os.path.join(paths['root'],"README.md"),
	'header':	os.path.join(paths['include'],"HEADER.md"),
	'footer':	os.path.join(paths['include'],"FOOTER.md"),
}

# Main function
def main():
	plugins = get_yaml_file(files['plugins'])
	libraries = get_yaml_file(files['libraries'])
	for plugin in plugins['build']:
		check_plugin(plugin)
	create_readme_file()
#	pprint.pprint(plugins)
#	pprint.pprint(libraries)
#	pprint.pprint(paths)
#	pprint.pprint(urls)
#	pprint.pprint(files)

# Get YAML file
def get_yaml_file(yaml_file):
	with open(yaml_file, 'r') as stream:
		try:
			return(yaml.load(stream))
		except yaml.YAMLError as exc:
			print(exc)
			sys.exit()
# Process a plugin
def check_plugin(plugin):
	data = get_plugin_data(plugin)
	check_plugin_compile(plugin,data)
	create_updater_file(plugin,data)
	create_dependency_file(plugin,data)
	create_desc_file(plugin,data)
	create_todo_file(plugin,data)
	create_cvar_file(plugin,data)
	create_plugin_file(plugin,data)
#	sys.exit()

# Get values from plugin
def get_plugin_data(plugin):
	compile = False
	sp_file = os.path.join(paths['root'],"scripting","%s.sp" % plugin)
	if not os.path.isfile(sp_file):
		print("ERROR: Cannot find plugin source file \"%s\"!" % sp_file)
		return dict()
	smx_file = os.path.join(paths['root'],"plugins","%s.smx" % plugin)
	if not os.path.isfile(smx_file):
		smx_file = os.path.join(paths['root'],"plugins/disabled","%s.smx" % plugin)
	if not os.path.isfile(smx_file):
		compile = True
	return process_plugin(sp_file,smx_file)

def process_plugin(sp_file,smx_file):
	pprint.pprint(sp_file)
	pprint.pprint(smx_file)
	with open(sp_file, 'r') as stream:
		try:
			source = stream.read()
		except:
			print("Could not load \"%s\"!" % sp_file)




#	tree = ast.parse(source)
#	FindFuncs().visit(tree)
#	fn_match = 
#	func_match = 
#	p = re.compile("CreateConVar\s*\(.*\)")
#	print(source)
#	print(p.match(source).groups())
#	pprint.pprint(fn_match)
#	fn_dict = fn_match.groupdict()
#	pprint.pprint(fn_dict)
#	sys.exit()
#	del fn_dict['args']
#	fn_dict['arg'] = [arg.strip() for arg in fn_dict['arg'].split(',')]
#        cvarVersion = CreateConVar("sm_ammocheck_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
#        cvarEnabled = CreateConVar("sm_ammocheck_enabled", "1", "sets whether ammo check is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	with open(smx_file, 'rb') as fp:
		plugin = smx.SourcePawnPlugin(fp)
#		pprint.pprint(dir(plugin))
		print 'Loaded %s...' % plugin
		"""
		print plugin.base
		print plugin.extract_from_buffer
		print plugin.name
		print plugin.natives
		print plugin.pcode
		print plugin.publics
		"""
		print plugin.stringbase
		print plugin.stringtab
		print plugin.stringtable
		print plugin.tags
		print plugin.myinfo
		for item in plugin.publics:
			pprint.pprint(item)
			pprint.pprint(dir(item))
#			print("%s: %s" % (item.name,item.value))
		sys.exit()
	return ""
# Compile plugin if missing our out of date, default to disabled
def check_plugin_compile(plugin,data):
	return ""

# Create Updater file
def create_updater_file(plugin,data):
	updater = KeyValues()
	template_file = os.path.join(paths['updater'],"_template.txt")
	updater.load_from_file(template_file)
	print(updater.kv)
#	updater.recurse_keyvalues()

# Create Dependency file
def create_dependency_file(plugin,data):
	return ""

# Create Description file
def create_desc_file(plugin,data):
	return ""

# Create Todo file
def create_todo_file(plugin,data):
	return ""

# Create CVAR file
def create_cvar_file(plugin,data):
	return ""

# Create Plugin Readme file
def create_plugin_file(plugin,data):
	return ""

# Create complete README.md
def create_readme_file():
	return ""

"""
#files to update
doc_path="$( cd "$( dirname "${bash_source[0]}" )" && pwd )"

# root sourcemod directory
sourcemod_path="$(dirname "${doc_path}")"

# github url to pull from
github_url="https://github.com/jaredballou/insurgency-sourcemod/blob/master"

# list of plugins
plugins_file="${doc_path}/plugins.jballou.txt"
plugins_list=$(cat "${plugins_file}")

# table of contents file
toc_file="${doc_path}/include/toc.md"

# finished readme file
readme_file="${sourcemod_path}/readme.md"

# directory for storing updater manifests
update_path="${sourcemod_path}/updater-data"

# url base for updater manifests
update_urlbase="http://ins.jballou.com/sourcemod"

# libraries to ignore when creating dependency lists
library_ignore="updater"

# add a file to the updater manifest
function add_file_to_update() {
	line="${1}"
	if [ $(grep -c -i "^${line}\$" "${doc_updater_file}") -eq 0 ]
	then
		echo "adding ${line} to files for ${item}"
		echo "${line}" >> "${doc_updater_file}"
	fi
}

# blank out toc file
echo > "${toc_file}"

#loop through all files
for item in $plugins_list
do
	echo "processing ${item}"

	# get base plugin name and source script
	# these paths refer to their location relative to sourcemod root
	plugin_path="plugins/${item}.smx"
	script_path="scripting/${item}.sp"

	# if the plugin doesn't exist, assume it is disabled
	if [ ! -e "../${plugin_path}" ]; then
		plugin_path="plugins/disabled/${item}.smx"
	fi

	# if the plugin is still not present, or is older than the source script, compile
	if [ ! -e "../${plugin_path}" ] || [ "../${plugin_path}" -ot "../${script_path}" ]; then
		echo "compiling ${item}"
		../scripting/spcomp "../${script_path}" -o"../${plugin_path}"
		if [ $? -gt 0 ]; then
			echo "abort: compilation of \"../${script_path}\" failed!"
			exit
		else
			git add "../${plugin_path}"
		fi
	fi

	# these are the actual on-disk paths for the files themselves
	plugin="${sourcemod_path}/${plugin_path}"
	script="${sourcemod_path}/${script_path}"
	update="${update_path}/update-${item}.txt"

	# and these are all the pieces that make up each plugin's documentation
	doc_updater_file="${doc_path}/plugins/updater/${item}.txt"
	doc_dependency_file="${doc_path}/plugins/dependencies/${item}.md"
	doc_desc_file="${doc_path}/plugins/description/${item}.md"
	doc_todo_file="${doc_path}/plugins/todo/${item}.md"
	doc_cvar_file="${doc_path}/plugins/cvar/${item}.md"
	doc_plugin_file="${doc_path}/plugins/${item}.md"

	# create updater file if missing
	if [ ! -e "${update}" ]
	then
		echo "creating update-${item}.txt in updater-data..."
		sed -e "s/myplugin/${item}/" "${update_path}/_template.txt" > "${update}"
	fi

	# create all pieces of the documentation if files are missing
	for piece in "${doc_updater_file}" "${doc_desc_file}" "${doc_todo_file}"
	do
		if [ ! -e "${piece}" ]
		then
			echo "creating ${piece}"
			touch "${piece}"
		fi
	done

	# merge items in the updater file and anything we added manually to the plugins/updater text file
	for line in $(egrep '(plugin|source)[":]' "${update}" | tr -d \" | awk '{print $1":"$2}'); do
		add_file_to_update "${line}"
	done
# >> "${doc_updater_file}"

	# these are lists of the items that we need to put into the updater
	add_file_to_update "plugin:path_sm/${plugin_path/disabled\//}"
	add_file_to_update "source:path_sm/${script_path}"

	# collect cvars
	grep createconvar "${script}" | grep -v '_version"' | sed -e 's/""/nullstring/g' | awk -f'"' -v ofs='' '{ for (i=2; i<=nf; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | sed -e 's/"//g' | awk -f',' '{print $1" "$2" "$3}' | sed -e 's/;;/,/g' | awk '{printf " * \""$1"\" \""$2"\" //"$3;for(i=4;i<=nf;i++){printf " %s", $i}printf "\n"}' | sed -e 's/nullstring//g' > "${doc_cvar_file}"

	# colelct dependencies
	echo -ne > "${doc_dependency_file}"

	# included files
	for include in $(grep -o '^#include <[^>]\+' "${script}" | cut -d'<' -f2)
	do
		if [ $(grep "^$(basename "${include}")\$" "${plugins_file}" -c) -gt 0 ]
		then
			echo " * [source include - ${include}.inc](${github_url}/scripting/include/${include}.inc?raw=true)" >> "${doc_dependency_file}"
			add_file_to_update "source:path_sm/scripting/include/${include}.inc"
		fi
	done

	# gamedata files
	for gamedata in $(grep -po 'loadgameconfigfile\([^\)]+\)' "${script}" | cut -d'"' -f2)
	do
		echo " * [gamedata/${gamedata}.txt](${github_url}/gamedata/${gamedata}.txt?raw=true)" >> "${doc_dependency_file}"
		add_file_to_update "plugin:path_sm/gamedata/${gamedata}.txt"
	done

	# translations
	for translation in $(grep -po 'loadtranslations\([^\)]+\)' "${script}" | cut -d'"' -f2)
	do
		echo " * [translations/${translation}.txt](${github_url}/translations/${translation}.txt?raw=true)" >> "${doc_dependency_file}"
		add_file_to_update "plugin:path_sm/translations/${translation}.txt"
	done

	# libraries
	for library in $(grep -po 'libraryexists\([^\)]+\)' "${script}" | cut -d'"' -f2)
	do
		if [ "$(grep "${library}" "${doc_path}/plugins.jballou.txt")" == "${library}" ]
		then
			echo " * [plugin - ${library}](#${library})" >> "${doc_dependency_file}"
		else
			# todo: make this use the library_ignore variable, for now just ignore updater
			if [ "${library}" != "updater" ]
			then
				echo " * [third-party plugin: ${library}](${github_url}/plugins/${library}.smx?raw=true)" >> "${doc_dependency_file}"
			fi
		fi
	done

	# make sure the updater url in the source script is correct
        cururl=$(grep -i '^#define.*update_url' "${script}" | cut -d'"' -f2)
	newurl="${update_urlbase}/update-${item}.txt"

	# make sure the version and name in the updater file is correct
	curver=$(grep '"latest".*"[0-9\.]*"' "${update}" | cut -d'"' -f4)
	newver=$(grep -i '^#define.*_version' "${script}" | cut -d'"' -f2)

	# get name from source script
        newname=$(grep -i '^#define.*plugin_name' "${script}" | cut -d'"' -f2)
        if [ "${newname}" == "" ]
        then
                newname=$(grep -m1 -p '^[\s]*name[\s]*=.*"' "${script}" | cut -d'"' -f2)
        fi
	# remove "[ins] " prefix from name
	newname=$(echo "${newname}" | sed -e 's/\[ins\] //')

	# get the description from the source script
        newdesc=$(grep -i '^#define.*plugin_description' "${script}" | cut -d'"' -f2)
        if [ "${newdesc}" == "" ]
        then
                newdesc=$(grep -m1 -p '^[\s]*description[\s]*=.*"' "${script}" | cut -d'"' -f2)
        fi

	# update notes line with name of plugin and description
	curnotes=$(grep -m1 -i '"notes".*"' "${update}" | cut -d'"' -f4|sed -e 's/[]\/$*.^|[]/\\&/g')
	newnotes=$(echo "${newname} - ${newdesc}" | sed -e 's/[]\/$*.^|[]/\\&/g')

	# create github friendly title and link name for anchor
        newtitle="${newname} ${newver}"
        newhref=$(echo "${newtitle}" | sed -e 's/ /-/g' -e 's/[^a-za-z0-9-]//g')

	# update url in script to point to updater file
	if [ "${cururl}" != "${newurl}" ]
	then
		echo "changing ${item} update_url from \"${cururl}\" to \"${newurl}\""
		sed -e "s,^\#define.*update_url[\s].*\$,\#define update_url \"${newurl}\"," -i "${script}"
	fi

	# update name in updater file
	if [ "${curnotes}" != "${newnotes}" ]
	then
		echo "changing ${item} title note from \"${curnotes}\" to \"${newnotes}\""
		sed -e "s\`\"notes\".*\$\`\"notes\"\t\t\"${newnotes}\"\`" -i "${update}"
	fi

	# update version in updater file
	if [ "${curver}" != "${newver}" ]
	then
		echo "bumping ${item} from ${curver} to ${newver}"
		sed -e "s,\"latest\".*\$,\"latest\"\t\t\"${newver}\"," -i "${update}"
	fi

	# update plugin documentation for readme

	# add entry to table of contents
	echo -e " * <a href='#user-content-${item}'>${newname} ${newver}</a>" >> "${toc_file}"

	# create plugin document file
	echo -e "<a name='${item}'>\n---\n### ${newtitle}</a>" > "${doc_plugin_file}"

	# short description
	echo "${newdesc}" >> "${doc_plugin_file}"
	echo "" >> "${doc_plugin_file}"

	# download links
	echo " * [plugin - ${item}.smx](${github_url}/${plugin_path}?raw=true)" >> "${doc_plugin_file}"
	echo " * [source - ${item}.sp](${github_url}/${script_path}?raw=true)" >> "${doc_plugin_file}"
	echo "" >> "${doc_plugin_file}"

	# include longer description document if available
	cat "${doc_desc_file}" >> "${doc_plugin_file}"
	echo "" >> "${doc_plugin_file}"

	# include dependency information
	if [ $(wc "${doc_dependency_file}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### dependencies" >> "${doc_plugin_file}"
		cat "${doc_dependency_file}" >> "${doc_plugin_file}"
		echo "" >> "${doc_plugin_file}"
	fi

	# include cvar listing
	if [ $(wc "${doc_cvar_file}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### cvar list" >> "${doc_plugin_file}"
		cat "${doc_cvar_file}" >> "${doc_plugin_file}"
		echo "" >> "${doc_plugin_file}"
	fi

	# include todo file
	if [ $(wc "${doc_todo_file}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### todo" >> "${doc_plugin_file}"
		cat "${doc_todo_file}" >> "${doc_plugin_file}"
		echo "" >> "${doc_plugin_file}"
	fi

	# update the updater files with the plugin and source items we have collected
	# todo: fix this hacky shitshow and do this a better way
	perl -i -p0e 's/("files"[^\{]*\{)[^\}]*\}/\1\nput_files_here\n\t\}/s' "${update}"
	sed -i -e "/put_files_here/{r ${doc_updater_file}" -e 'd}' "${update}"
	sed -i -e 's/\(plugin\|source\):\(.*\)$/\t\t"\1"\t"\2"/g' "${update}"

#	updater_files=$(sort -u "${doc_updater_file}" | sed -e 's/#.*//' -e 's/[ ^i]*$//' -e '/^$/ d')
#	sed -i -e "/put_files_here/{r ${doc_updater_file}" -e 'd}' "${update}"
#	sed -i -e "#put_files_here#$(echo $updater_files | sed -e 's/[ \t]\+/\n/g' | 
#	echo $updater_files | sed -e 's/[ \t]\+/\n/g' | sed -e "s/^\([^:]*\):\(.*\)$/\t\t'\1'\t'\2'/g"

done
echo >> "${toc_file}"
# create finished readme
cat "${doc_path}/include/header.md" "${doc_path}/include/toc.md" "${doc_path}/plugins/"*.md "${doc_path}/include/footer.md" > "${readme_file}"

git add *
"""
if __name__ == "__main__":
	main()
