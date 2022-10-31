import json
from zipfile import ZIP_DEFLATED, ZipFile
import argparse

import os
import shutil
import re

orig_dir = os.path.dirname(__file__)

desc = """
Neonwood Game Packaging utility.

requires python 3.7

This package is not needed to build neonwood projects
merely a convenience for helping create shareable builds.

IMPORTANT!

the project should be compiled with the following flags.

zig build -fstage1 -Dtarget=x86_64-windows -Dvulkan_validation=false

usage: 

manage.py cognesia

Reads a package file under
`projects/cognesia/nwpackage.json`

And creates an output package under packages/
"""

"""
nwpackage.json format
--

keys: 

"project_name": string 
The name of the package to assemble, this is used to name the final zip file

"exe_name": string
(optional) name of the main executable for this package. a null value results
in no main exe being marked for testing

"extra_binaries": [string]
list of strings that 

"files_to_exclude": [string]
list of regexes that are used to exclude engine content, if this is empty
or if not set, then all engine content is included


A note about packaging:
the corresponding project's content/ folder is always packaged.... 
this isn't quite working just yet

"""

parser = argparse.ArgumentParser(
    description = desc
)

parser.add_argument("packages", nargs="+")

def panic(s, e):
    print(s)
    print(e)
    raise e

def readPackage(packageName):
    package = {}
    fpath = f"projects/{packageName}/nwpackage.json"
    try:
        with open(os.path.join(orig_dir, fpath)) as f:
            package = json.load(f)

    except FileNotFoundError as e:
        panic("Unable to load package, nwpackage is not in path.", e)
    
    except json.decoder.JSONDecodeError as e:
        panic(f"Bad json data: {os.path.abspath(os.path.join(orig_dir, fpath))}", e)

    print(package)
    return package

default_binaries = ["glfw3.dll"]
engine_content = []
package_content = {}

def getContentInPath(contentPath):
    content = []
    p = os.path.join(orig_dir, contentPath)
    for root, dir, files in os.walk(p):
        for file in files:
            relPath = os.path.relpath(root, contentPath)
            if(relPath == "."):
                relPath = ""
            relPath = relPath.replace("\\", "/")
            content.append(relPath + "/" + file)
    return content

if __name__ == "__main__":
    args =  parser.parse_args()

    engine_content = getContentInPath("content")

    for package in args.packages:
        packageInfo = readPackage(package)
        packageContent = getContentInPath(f"projects/{package}/content")
        engineContentFiltered = engine_content
        for excludeFile in packageInfo["files_to_exclude"]:
            r = re.compile(excludeFile)
            engineContentFiltered = [i for i in engineContentFiltered if not r.match(i) and not 'sources' in i]

        packageDir = os.path.join(orig_dir, f"packages/{package}")
        os.makedirs(packageDir, exist_ok=True)
        # copy over engine content
        os.makedirs(packageDir + "/content", exist_ok=True)

        for content in engineContentFiltered:
            shutil.copy(orig_dir + "/content/" + content, packageDir + "/content/" + content)
            
        # copy over project content
        # ... todo..

        # copy over dlls and exes
        binaries = default_binaries.copy()
        exe_name = packageInfo["exe_name"]
        if(os.name == 'nt'):
            exe_name = exe_name + ".exe"
        binaries.append("zig-out/bin/" + exe_name)
        for binary in binaries:
            shutil.copy(binary, packageDir)

        # create zip file under packages/

        zipFileName = packageInfo["project_name"] + ".zip"
        if(os.name == 'posix'):
            zipFileName = packageInfo["project_name"] + "_linux.zip"
        zipPath = orig_dir + "/packages/" + zipFileName
        print(zipPath)
        with ZipFile(zipPath, 'w', compresslevel=9, compression=ZIP_DEFLATED) as z:
            for root, dirs, files in os.walk(packageDir):
                for file in files:
                    if('sources' not in root):
                        fpath = os.path.join(root, file)
                        z.write(fpath, os.path.relpath(fpath, packageDir))

            z.close()

        
