import os
import sys
import argparse
import json
import colorama
import subprocess as sub
import asyncio
import datetime
import logging

colorama.init(autoreset=True)

orig_dir = os.path.abspath(os.path.dirname(__file__))
config_path = os.path.join(orig_dir, 'config.json')
local_output_path = os.path.join(orig_dir, 'output')

class PostSrc:

    def __init__(self, name, fpath, folder, parseout, project_folder, config):
        self.fpath = fpath
        self.name = name
        self.folder = folder
        self.content = parseout['content']
        self.meta = parseout['metadata']
        self.project_folder = project_folder
        self.config = config
    
    def __repr__(self):
        return f"\n====== [name]: {self.name} ======\n" +\
             f"[file]: {self.fpath}\n[project_root]: {self.project_folder}" +\
             f"[folder]: {self.folder}\n[meta]: {json.dumps(self.meta, indent=2)}\n===============\n"

        ostr = self.content.replace("<!--- METABLOCK -->", self.meta_to_html())
        return ostr

    def get_asset_path(self):
        http_or_https = 'https' if self.config['use_https'] else 'http'
        ostr = http_or_https + '://' + self.config['host'] + '/assets'
        return ostr
    
    def content_to_html(self):
        ostr = self.content.replace("<!--- METABLOCK -->", self.meta_to_html())
        ostr = ostr.replace("$ASSETPATH()", self.get_asset_path())
        return ostr
    
    def to_html(self, site_info):
        content = self.content
        template = site_info.get_template(self.meta['template'])
        ostr = template.replace("<!-- TITLE MARKER -->", self.meta['title'])
        ostr = ostr.replace("<!-- POST MARKER -->", self.content_to_html())
        ostr = ostr.replace("<!-- RIGHT NAV MARKER -->", site_info.generate_right_nav())
        return ostr
    
    def meta_to_html(self):
        ostr = '<p class="metablock">\n'
        ostr += f"date: {self.meta['date']}<br/>\n"
        ostr += f"author: {self.meta['author']}\n"
        ostr += f'</p>\n'
        return ostr

def parse_meta(meta_str):
    metad = {}
    try:
        metad = json.loads(meta_str)
    except:
        print(meta_str)
        raise
    return metad

async def make_pandoc_content(name, fpath, rootpath, project_folder, config):
    try:
        metadata = parse_meta(await async_cmd( name, fpath, f"pandoc --template=metadata.pandoc-tpl \"{fpath}\""))
    except:
        print(f"error in: {name} file: [{fpath}]")
        raise

    html_str = await async_cmd( name, fpath, f"pandoc -t html --ascii {fpath}")
    html_str = html_str.decode('UTF-8')

    content = PostSrc(
        name,
        fpath,
        rootpath,
        {"content": html_str, "metadata" : metadata},
        project_folder,
        config
    )
    return content
    
    
async def async_cmd(name, fpath, cmd):
    proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout = asyncio.subprocess.PIPE,
        stderr = asyncio.subprocess.PIPE,
    )
    
    stdout, stderr = await proc.communicate()
    return stdout

class Site:
    def __init__(self, config=None):
        self.src_root = "content"
        self.template_root = "templates"
        site_name = config['host']

        self.site_root = "."
        self.site_name = site_name
        
        if site_name is not None:
            if config['use_https']:
                self.site_root = 'https://'+site_name
            else:
                self.site_root = 'http://'+site_name

        self.posts = parse_all(self.src_root, config)
        self.odir = "output"
    
    def get_template(self, template_name):
        ostr = None
        with open(self.template_root +'/'+ template_name) as f:
            ostr = f.read()
        ostr = ostr.format(
            CSS_PATH=self.site_root + "/style/style.css",
            FAVICON_PATH=self.site_root + "/favicon.ico",
            INDEX_PATH=self.site_root + "/index.html"
        )
        return ostr

    def generate_index_html(self):
        content_str = ""
        template = self.get_template('template.html')
        first = True
        for post in self.posts:
            if post.meta['state'] == 'posted':
                if not first:
                    content_str += '<hr class="post_divider">\n' 
                content_str += post.content_to_html() 
                first = False

        ostr = template.replace("<!-- TITLE MARKER -->", "Peter's Blog")
        ostr = ostr.replace("<!-- RIGHT NAV MARKER -->", self. generate_right_nav())
        ostr = ostr.replace("<!-- POST MARKER -->", content_str)
        return ostr

    
    def generate_right_nav(self):
        ostr = '<ul class="recent_posts_list">\n'
        nav_entry_templ = '<li class="recent_post_li">'+\
        '<a class="recent_post_li" href="{post_link}">'+\
        '<h3 class="recent_post_link">'+\
        '{post_name}</h3></a></li>\n'
        for post in self.posts:
            if post.meta['state'] == 'posted':
                ostr += nav_entry_templ.format(post_link = self.site_root + f"/{post.name}.html",
                        post_name = post.meta['title']
                )

        ostr += '</ul>\n'
        return ostr

    def build_htmls(self):
        os.makedirs(self.odir, exist_ok=True)
        for post in self.posts:
            ostr = post.to_html(self)
            if post.name == 'index':
                ostr = self.generate_index_html()
            print(ostr)
            with open(os.path.join(self.odir, f'{post.name}.html'), 'w', encoding="UTF-8") as f:
                f.write(ostr)
    
    def build_site(self):
        self.build_htmls()
        os.makedirs(self.odir + "/style", exist_ok=True)
        os.system(f"cp templates/style/style.css {self.odir}/style/style.css")
        os.system(f"cp -r content/* {self.odir}/")
        os.system(f"cp -r assets {self.odir}")

def parse_all(src_root, config):
    meta_dict = {}

    loop = asyncio.get_event_loop()

    tasks = []
    for root, dirs, files in os.walk(src_root, topdown=False):
        for name in files:
            if name.endswith(".md"):
                tasks.append(make_pandoc_content(name.strip('.md'), os.path.join(root, name), root, src_root, config))
    content_results = loop.run_until_complete(asyncio.gather(*tasks))
    content_results.sort(key=lambda x: datetime.datetime.strptime(x.meta['date'], '%Y-%m-%d'), reverse=True)
    return content_results

class Program:

    def __init__(self):
        self.config = {}
    
    def build_output(self):
        try:
            sub.run(["pandoc", '--version'], check=True)
        except:
            print("Pandoc version check failed, is pandoc installed?")
        site = Site(self.config)
        
        site.build_site()
        os.system(f'cp -r output/* {self.config["deploy_location"]}')

    def new_config(self):
        self.config['host'] = '127.0.0.1'
        self.config['use_https'] = False
        self.config['deploy_location'] = os.path.join(orig_dir, 'windows_server/html')
        if os.path.exists(config_path):
            response = input(f"{config_path} already exists, would you like to overwrite it?")
            if not bool(response):
                return
        with open(config_path, 'w') as f:
            json.dump(self.config, f, indent = 2)
            print(f"saving new config to {config_path}")

    def load_config(self):
        with open(config_path) as f:
            self.config = json.load(f)
            print(f"loaded config from {config_path}")

if __name__ == "__main__":
    # load configs from config.json
    prog = Program()
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--new-config", "-n", action="store_true", help="Creates a new configuration")

    args = parser.parse_args()
    if args.new_config:
        prog.new_config()
    else:   
        prog.load_config()
        prog.build_output()



