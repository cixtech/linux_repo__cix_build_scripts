#!/usr/bin/python3

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

# Description: release the repo manifests to github
# Author: Xinjun
# Date: 2025-09-17
# Revision: original v1.0
#

import os, sys
import requests
import base64
import json
import time
import subprocess

import logging
import string
import random
from typing import Any, Tuple, List

logger = logging.Logger(__name__)

class GitClient(object):

    def __init__(self, cwd=os.getcwd()):
        self._cwd = cwd

    def run(self, cmd, shell=False)->str:
        ret = subprocess.run(args=cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, shell=shell, encoding="utf-8", cwd=self._cwd)
        if ret.returncode != 0:
            raise Exception(f"Git command err:cwd: {self._cwd} cmd:{' '.join(cmd)} , err: {ret.stderr}, {ret.stdout}")
        else:
            return ret.stdout
        
    def init(self) -> str:
        command = ['git', 'init', '.']
        return self.run(cmd=command)
        
    def clone(self, url: str, repo: str, branch:str="master", new_remote_name=None, dest=None, single_branch=False):
        
        remote = f'ssh://{url}/{repo}'
        command = ['git', 'clone']
        if single_branch:
            command.append("--single-branch")
        command.extend(['-b', branch, remote])
        if new_remote_name:
            command.extend(["--origin", "release-git"])
        
        if dest:
            command.append(dest)
        return self.run(cmd=command)

    def push(self, remote: str, branch: str, skip_validation=False, config=None):
        # git push  origin branch_name
        cmd = ['git']
        if config:
            cmd.extend(['-c', config])
        cmd.append('push')
        if skip_validation:
            cmd.extend(['-o', 'skip-validation'])

        cmd.extend([remote, branch])
        logger.info(f"gitpush: {' '.join(cmd)}")
        return self.run(cmd=cmd)
    
    def add(self, file:str):
        cmd = ['git', 'add', file]
        return self.run(cmd=cmd)

    def commit(self, commit_info: str):
        cmd = [
            'git',
            'commit',
            '--allow-empty',
            '-m',
            commit_info    
        ]
        return self.run(cmd=cmd)
    
    def amend_commit(self):
        cmd = ['git', 'commit', '--amend', '-CHEAD']
        return self.run(cmd=cmd)

    def commit_by_file(self, message: str, amend=False):

        commit_file = ''.join(random.choices(string.ascii_letters, k=8))
        tmp_file = f"/tmp/{commit_file}"

        with open(tmp_file, "w") as f:
            f.write(message)

        cmd = ["git", "commit",  "--allow-empty", "-F", tmp_file] 
        if amend :
            cmd.append("--amend")
        try:
            self.run(cmd=cmd)
        except Exception:
            raise Exception
        finally:
            os.remove(tmp_file)

    def set_cwd(self, cwd: str):
        self._cwd = cwd
    
    def check_diff(self):
        cmd = ['git','status']

        return self.run(cmd=cmd)
    
    def add_remote(self, remote_name:str, remote_url:str):
        try:
            remove_remote_cmd = ["git", "remote", "remove", remote_name]
            self.run(cmd=remove_remote_cmd)
        except Exception as err:
            ...
        cmd = ["git", "remote", "add", remote_name, remote_url]
        return self.run(cmd=cmd)
    
    def checkout(self, branch:str, options:List[str], revision=None):
        cmd = ["git", "checkout"]
        cmd.extend(options)
        cmd.append(branch)
        if revision:
            cmd.append(revision)

        return self.run(cmd=cmd)
    
    def cherry_pick(self, revision:str):
        """
        1. git cherry-pick 
        
        """
        cmd = ["git", "cherry-pick", revision]
        return self.run(cmd=cmd)
    
    def reset(self, revision:str, hard=False):
        """
        git reset --soft/--hard revision
        """
        cmd = ["git", "reset"]
        if hard:
            cmd.append("--hard")
        else:
            cmd.append("--soft")
        cmd.append(revision) 
        return self.run(cmd=cmd)
    
    def soft_reset(self, revision:str):
        return self.reset(revision=revision, hard=False)
    
    def hard_reset(self, revision:str):
        return self.reset(revision=revision, hard=True)
    
    def get_commit_id(self) -> str:
        cmd = ["git", "log", "-n1", "--format=%H"]
        out = self.run(cmd=cmd)
        return out.strip()
    
    def get_first_commit_id(self) -> str:
        cmd = 'git log --reverse --pretty=format:"%H" | head -n 1'
        out = self.run(cmd=cmd, shell=True)
        return out.strip()

    def get_commit_from_heads(self, head:str) -> str:
        cmd = ["git", "log", "-n1", head, "--format=%H"]
        out = self.run(cmd=cmd)
        return out.strip()
    
    def get_commits_id(self, after_commit:str, before_commit:str) -> List:
        cmd = ["git", "log", f"{after_commit}..{before_commit}", "--format=%H"]
        out = self.run(cmd=cmd)
        res = []
        for commit_id in out.split('\n'):
            if commit_id:
                res.append(commit_id)
        return res
    
    def get_tree(self, branch:str) -> str:
        cmd = ["git", "log", "-n1", "--format=%T"]
        cmd.append(branch)
        out = self.run(cmd=cmd)
        return out.split()
    
    def fetch_branch(self, remote_name:str, branch:str):
        cmd = ["git", "fetch", remote_name, branch]
        return self.run(cmd=cmd)

###########################################################################################################

DEBUG = False

PATH_HOME = ''
PATH_WORKSPACE = ''

GITHUB_TOKEN = ''
GITHUB_USERNAME = ''
GITHUB_ORG_NAME = ''
GITHUB_OWNER = ''

CONFIG_FILE = ''
REPO_NAME = ''
BRANCH_NAME = ''

def loadJson(path):
    try:
        f = open(path, "r", encoding = "utf-8")
        txt = f.read()
        f.close()
        return json.loads(txt)
    except Exception as e:
        print('load json failed.')
    return json.loads('[]')

def saveJson(data, path):
    try:
        f = open(path, "w", encoding = "utf-8")
        f.write(json.dumps(data, indent=2, ensure_ascii=False))
        f.close()
    except Exception as e:
        print('save json failed.')

def getValue(str, key):
    keyLen = len(key)
    iStart = str.find(key+'="')
    if iStart > 0:
        iStart = iStart + keyLen + 2
        iEnd = str.find('"', iStart)
        if iEnd > iStart:
            return str[iStart: iEnd], iStart, iEnd
    return '', 0, 0

def runApp(cmd):
    result = ''
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    try:
        lines = 0
        while True:
            line = proc.stdout.readline()
            if not line and proc.poll() != None:
                break
            result = result + line.decode('utf-8')
            lines = lines + 1
    except Exception:
        print(f'run [{cmd}] exception')
    finally:
        proc.stdout.close()
    return result

def loadConfig(file):
    content = ''
    projects = []
    try:
        ext = False
        remote = False
        ignore = False
        fIn = open(file, 'r', encoding='utf-8')
        for line in fIn.readlines():
            strip = line.strip()
            if ignore:
                if strip.endswith('/>'):
                    ignore = False
                continue
            if strip.startswith('<remote ') or strip.startswith('<default '):
                if not remote:
                    content += f'  <remote name="origin" fetch="https://github.com/{GITHUB_OWNER}" />\n'
                    content += f'  <default remote="origin" sync-j="4" sync-c="true" sync-tags="false" />\n'
                    remote = True
                if not strip.endswith('/>'):
                    ignore = True
                    continue
                else:
                    ignore = False
            if strip.startswith('<project '):
                if not ext:
                    #content += f'  <project path="ext" name="{REPO_NAME}_ext", groups="cix", revision="{BRANCH_NAME}" />\n'
                    projects.append({'name': f'{REPO_NAME}_ext', 'path': 'ext', 'revision': BRANCH_NAME})
                    ext = True
                path, iStart, iEnd = getValue(line, 'path')
                name, iStart, iEnd = getValue(line, 'name')
                revision, iStart, iEnd = getValue(line, 'revision')
                if DEBUG:
                    revision = 'main' # for debug test 
                name = name.replace('/', '__')
                if strip.endswith('/>'):
                    content += f'  <project path="{path}" name="{name}" groups="cix" revision="{revision}" />\n'
                else:
                    content += f'  <project path="{path}" name="{name}" groups="cix" revision="{revision}">\n'
                projects.append({'name': name, 'path': path, 'revision': revision})
            else:
                content += line
        fIn.close()
    except Exception as e:
        print(f'error for {file}: {e}')
        exit(1)
    return content, projects

def gitExists(gitName):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'{gitName} exists!')
            return True
        elif response.status_code == 404:
            print(f'{gitName} does not exist!')
            return False
        else:
            print(f'check {gitName} fail: {response.status_code}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def branchExists(gitName, branch):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/git/ref/heads/{branch}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'{branch} exists!')
            return True
        elif response.status_code == 404:
            print(f'{branch} does not exist!')
            return False
        else:
            print(f'check branch {branch} fail: {response.status_code}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def createGit(gitName):
    try:
        if len(GITHUB_ORG_NAME) > 0:
            url = f'https://api.github.com/orgs/{GITHUB_OWNER}/repos'
        else:
            url = f'https://api.github.com/user/repos'
        response = requests.post(url,
                                json={
                                    'name': gitName,
                                    'description': f'Create {gitName} via api',
                                    'private': False,
                                    'auto_init': True
                                    },
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'create {gitName} success!')
            return True
        else:
            print(f'create {gitName} fail: {response.json()}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def getBranchSHA(gitName, branch = 'main'):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/git/ref/heads/{branch}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            return response.json()['object']['sha']
        else:
            return ''
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return ''

def getFileSHA(gitName, remoteFile, branch = 'main'):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/contents/{remoteFile}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                },
                                params={
                                    'ref': branch
                                })
        if response.status_code in [200, 201]:
            return response.json()['sha']
        else:
            return ''
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return ''

def createBranch(gitName, newBranch, baseBranch = 'main'):
    if branchExists(gitName, newBranch):
        return True
    sha = getBranchSHA(gitName, baseBranch)
    if len(sha) < 1:
        print(f'Cannot get the sha form the branch {baseBranch}')
        return False
    print(f'main sha: {sha}')
    try:
        response = requests.post(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/git/refs',
                                json={
                                    'ref': f'refs/heads/{newBranch}',
                                    'sha': sha
                                    },
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'create branch {newBranch} success!')
            return True
        else:
            print(f'create branch {newBranch} fail: {response.json()}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def commitGitFile(content, gitName, remoteFile, branch = 'main'):
    sha = getFileSHA(gitName, remoteFile, branch)
    data = {'message': f'Commit the file {remoteFile} via api',
            'content': content,
            'branch': branch
            }
    if len(sha) > 0:
        data['sha'] = sha
    try:
        response = requests.put(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/contents/{remoteFile}',
                                json=data,
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'commit {remoteFile} success!')
            return True
        else:
            print(f'commit {remoteFile} fail: {response.json()}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

if __name__ == '__main__':
    args = sys.argv
    count = len(args)
    i = 0
    while i < count:
        if args[i] == '-h':
            print(f'{args[0]} <options>')
            print(f'    -t <token>:               the access token of github')
            print(f'    -u <user name>:           the user name of github')
            print(f'    -c <config file>:         the config file (default.xml)')
            print(f'    -r <repo name>:           the repo name of github')
            print(f'    -b <branch name>:         the branch name of the repo')
            print(f'    -o <organization name>:   the organization name of the github api')
            sys.exit(0)
        elif args[i] == '-t':
            i = i + 1
            GITHUB_TOKEN = args[i]
        elif args[i] == '-u':
            i = i + 1
            GITHUB_USERNAME = args[i]
        elif args[i] == '-c':
            i = i + 1
            CONFIG_FILE = args[i]
        elif args[i] == '-r':
            i = i + 1
            REPO_NAME = args[i]
        elif args[i] == '-b':
            i = i + 1
            BRANCH_NAME = args[i]
        elif args[i] == '-o':
            i = i + 1
            GITHUB_ORG_NAME = args[i]
        elif args[i] == '--debug':
            DEBUG = True
        i = i + 1

    if len(GITHUB_TOKEN) < 1:
        print(f'Please input the github token with -t')
        sys.exit(0)
    if len(GITHUB_USERNAME) < 1:
        print(f'Please input the github username with -u')
        sys.exit(0)
    if len(REPO_NAME) < 1:
        print(f'Please input the repo name with -r')
        sys.exit(0)
    if len(REPO_NAME) < 1:
        print(f'Please input the repo name with -r')
        sys.exit(0)
    if len(BRANCH_NAME) < 1:
        print(f'Please input the branch name with -b')
        sys.exit(0)
    # if len(GITHUB_ORG_NAME) < 1:
    #     print(f'Please input the organization name with -n')
    #     sys.exit(0)
    
    if len(GITHUB_ORG_NAME) > 0:
        GITHUB_OWNER = GITHUB_ORG_NAME
    else:
        GITHUB_OWNER = GITHUB_USERNAME

    if not os.path.exists(CONFIG_FILE):
        print(f'Config file {CONFIG_FILE} does not exist')
        sys.exit(0)

    PATH_HOME = os.path.realpath(os.path.join(__file__, '..'))
    PATH_WORKSPACE = os.path.realpath(os.path.join(CONFIG_FILE, '..', '..'))
        
    print(f'PATH_HOME: {PATH_HOME}')
    print(f'PATH_WORKSPACE: {PATH_WORKSPACE}')
    
    content, projects = loadConfig(CONFIG_FILE)
    print(content)
    print(projects)

    # create repo manifests    
    if not gitExists(REPO_NAME):
        createGit(REPO_NAME)

    # create repo branch
    createBranch(REPO_NAME, BRANCH_NAME, 'main')

    # commit the default.xml
    content = base64.b64encode(content.encode()).decode()
    print(content)
    commitGitFile(content, REPO_NAME, 'default.xml', BRANCH_NAME)
    
    time.sleep(0.5)
    # process all projects
    i = 0
    count = len(projects)
    while i < count:
        time.sleep(0.5)
        if not gitExists(projects[i]['name']):
            createGit(projects[i]['name'])
        i = i + 1

    if DEBUG:
        exit(0)

    i = 0
    count = len(projects)
    while i < count:
        path = os.path.join(PATH_WORKSPACE, projects[i]['path'])
        if os.path.exists(path):
            gitClient = GitClient(cwd=path)
            gitClient.add_remote('github', f'https://github.com/{GITHUB_OWNER}/{projects[i]['name']}')
            gitClient.push(remote='github', branch=projects[i]['revision'], skip_validation=True)
        else:
            print(f'path {path} does not exist!')
        i = i + 1
