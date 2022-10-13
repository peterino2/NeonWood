from email.policy import default
import json
from posixpath import relpath
from zipfile import ZIP_BZIP2, ZipFile
import argparse

import os
import shutil
import re
import zipfile

orig_dir = os.path.dirname(__file__)

desc = """
Neonwood Game Packaging utility.

Reads a nwpackage.py file under
`projects/{project_name}/nwpackage.json`

And creates an output package under builds/
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
        for excludeFile in packageInfo["filesToExclude"]:
            r = re.compile(excludeFile)
            engineContentFiltered = [i for i in engineContentFiltered if not r.match(i)]

        packageDir = os.path.join(orig_dir, f"packages/{package}")
        os.makedirs(packageDir, exist_ok=True)
        # copy over engine content
        os.makedirs(packageDir + "/content", exist_ok=True)

        for content in engineContentFiltered:
            shutil.copy(orig_dir + "/content" + content, packageDir + "/content" + content)
            
        # copy over project content
        # ... todo..

        # copy over dlls and exes
        binaries = default_binaries.copy()
        binaries.append("zig-out/bin/" + packageInfo["exe_name"])
        for binary in binaries:
            shutil.copy(binary, packageDir)

        # create zip file under packages/

        zipFileName = packageInfo["projectName"] + ".zip"
        zipPath = orig_dir + "/packages/" + zipFileName
        print(zipPath)
        with ZipFile(zipPath, 'w', compresslevel=9, compression=ZIP_BZIP2) as z:
            for root, dirs, files in os.walk(packageDir):
                for file in files:
                    fpath = os.path.join(root, file)
                    z.write(fpath, os.path.relpath(fpath, packageDir))

            z.close()

        
