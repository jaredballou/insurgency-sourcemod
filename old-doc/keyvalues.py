import os, sys, yaml, pprint
import sys
from collections import OrderedDict
              
class KeyValues:
    kv = OrderedDict()
    def load_from_file(self, path):
        with open(path) as file:
            self.kv = self.parse(file.read())

    def save_to_file(self, path):
        with open(path, "w") as file:
            self.recurse_keyvalues(file)

    def recurse_keyvalues(self, out = sys.stdout, kv = None, depth = 0):
        if kv is None:
            kv = self.kv
        for k, v in kv.items():
            indent = ""
            for i in range(0, depth):
                indent += "\t"
            if isinstance(v, dict):
                out.write("%s\"%s\"\n%s{\n" % (indent,k,indent))
                self.recurse_keyvalues(out, v, depth + 1)
                out.write("%s}\n" % (indent))
            else:
                out.write("%s\"%s\"\t\t\"%s\"\n" % (indent,k,v))

    def parse(self, s):
        TYPE_BLOCK = 0
        TYPE_ARRAY = 1
        i = 0
        line = 1
        depth = 0
        tree = [OrderedDict()]
        treeType = [TYPE_BLOCK]
        keys = [None]
        while i < len(s):
            char = s[i]
            if char == " " or char == "\t":
                pass
            elif char == "\n":
                line += 1
                if i + 1 < len(s) and s[i + 1] == "\r":
                    i += 1
            elif char == "\r":
                line += 1
                if i < len(s) and s[i + 1] == "\n":
                    i += 1
            elif char == "\"":
                i += 1
                startindex = i
                resultstring = ""
                while i < len(s):
                    char = s[i]
                    if char == "\"" or char == "\n" or char == "\r":
                        break
                    if char == "\\":
                        i += 1
                        char = s[i]
                        if char == "\"" or char == "\\" or char == "\'":
                            pass
                        elif char == "n":
                            char = "\n"
                        elif char == "r":
                            char = "\r"
                        else:
                            raise Exception("Invalid Escape Character \"{}\" at line {}".format(char, line))
                    resultstring += char
                    i += 1
                if i == len(s) or char == "\n" or char == "\r":
                    raise Exception("Unterminated string at line {}".format(line))
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    if keys[len(keys) - 1] == None:
                        keys[len(keys) - 1] = resultstring
                    else:
                        tree[len(tree) - 1][keys[len(keys) - 1]] = resultstring
                        keys[len(keys) - 1] = None
                elif treeType[len(treeType) - 1] == TYPE_ARRAY:
                    tree[len(tree) -1].append(resultstring)
                if char != "\"":
                    i -= 1
            elif char >= "0" and char <= "9":
                i += 1
                startindex = i
                while i < len(s):
                    char = s[i]
                    if (char < "0" or char > "9") and char != "." and char != "x":
                        break
                    i += 1
                try:
                    resultnumber = int(x[startindex:i - startindex])
                except ValueError:
                    raise Exception("Invalid number at line {} (offset {})".format(line, i))
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    if keys[len(keys) - 1] is None:
                        raise Exception("A number can't be the key of a value at line {} (offset {})".format(line, i))
                    else:
                        tree[len(tree) - 1][keys[len(keys)]] = resultnumber
                        keys[len(keys) - 1] = None
                elif treeType[len(treeType) - 1] == TYPE_ARRAY:
                    tree[len(tree) - 1].append(resultnumber)
                i -= 1
            elif char == "{":
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    if keys[len(keys) - 1] is None:
                        raise Exception("A block needs a key at line {} (offset {})".format(line, i))
                    tree.append({})
                    treeType.append(TYPE_BLOCK)
                    keys.append(None)
            elif char == "}":
                if len(tree) == 1:
                    raise Exception("Mismatching bracket at line {} (offset {})".format(line, i))
                if treeType.pop() != TYPE_BLOCK:
                    raise Exception("Mismatching brackets at line {} (offset {})".format(line, i))
                keys.pop()
                obj = tree.pop()
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    tree[len(tree) - 1][keys[len(keys) - 1]] = obj
                    keys[len(keys) - 1] = None
                else:
                    tree[len(tree) - 1].append(obj)
            elif char == "[":
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    if keys[len(keys) - 1] is None:
                        raise Exception("An array needs a key at line {} (offset {})".format(line, i))
                    tree.append([])
                    treeType.append(TYPE_ARRAY)
                    keys.append(None)
            elif char == "]":
                if len(tree) == 1:
                    raise Exception("Mismatching bracket at line {} (offset {})".format(line, i))
                if treeType.pop() != TYPE_ARRAY:
                    raise Exception("Mismatching brackets at line {} (offset {})".format(line, i))
                keys.pop()
                obj = tree.pop()
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    tree[len(tree) - 1][keys[len(keys) - 1]] = obj
                    keys[len(keys) - 1] = None
                else:
                    tree[len(tree) - 1].append(obj)
            elif (char >= "a" and char <= "z") or (char >= "A" and char <= "Z") or char == "_" or char == "$" or char == "-":
                startindex = i
                resultstring = ""
                while i < len(s):
                    char = s[i]
                    if (char >= "a" and char <= "z") or (char >= "A" and char <= "Z") or char == "_" or char == "$" or char == "-":
                        resultstring += char
                        i += 1
                    else:
                        break
                if treeType[len(treeType) - 1] == TYPE_BLOCK:
                    if keys[len(keys) - 1] is None:
                        keys[len(keys) - 1] = resultstring
                    else:
                        tree[len(tree) - 1][keys[len(keys) - 1]] = resultstring
                        keys[len(keys) - 1] = None
                elif treeType[len(treeType) - 1] == TYPE_ARRAY:
                    tree[len(tree) - 1].append(resultstring)
                i -= 1
            elif char == "/":
                i += 1
                while i < len(s):
                    char = s[i]
                    i += 1
                    if char == "\n":
                        line += 1
                        break
            else:
                raise Exception("Unexpected character \"{}\" at line {} (offset {})".format(char, line, i))
            i += 1
        if len(tree) != 1:
            raise Exception("Missing Brackets")
        return tree[0]


