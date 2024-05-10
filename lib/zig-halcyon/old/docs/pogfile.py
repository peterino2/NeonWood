# do not look for pogfiles in this directory
# exclude_paths = ["dont_include"]  

# these files/directories shall be imported, even if they're out of path or if they're 
# include_paths = ["test_simple.py", "dont_include/test_anyway/"] 

# autoindex = False # change this to true to automatically search for pogfile.py in inferior directories.

@job(desc="Hello World job, this is the toplevel default target")
def top():
    print("Hello friend! from python")
    env.run("echo", "You can use env.run() to run a subprocess run similar to subprocess.run()")
    env.system("echo \"You can use env.system to try and use a system shell.\"")


@job("top", desc="This is a job that depends on the top job, dependencies are specified as strings")
def depends_on_top():
    pass # blank job, does nothing
