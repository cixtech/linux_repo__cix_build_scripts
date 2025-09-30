#!/usr/bin/python3

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

# Description: convert the manifest file from developemnt to branch
# Author: Xinjun
# Date: 2025-06-19
# Revision: original v1.0
#

import os, sys

if __name__ == '__main__':
    rootPath = os.environ['PATH_ROOT']
    scriptPath = rootPath + '/build-scripts'
    print('scriptPath path: '+ rootPath)

    result = '"Module","Description","Dependence","Include"'
    for file in sorted(os.listdir(scriptPath)):
        if file.startswith('build-') and file.endswith('.sh'):
            print(scriptPath + '/' + file)
            try:
                module = file #file[6:len(file)-3]
                desc = ''
                dep = ''
                inc = ''
                fIn = open(scriptPath + '/' + file, 'r', encoding='utf-8')
                for line in fIn.readlines():
                    line = line.strip()
                    if line.startswith('readonly DO_DESC_build="'):
                        desc = line[24:len(line) - 1]
                    elif line.startswith('DEPENDENT_MODULES="'):
                        dep = line[19:len(line) - 1]
                    elif line.startswith('"build-'):
                        if len(inc) > 0:
                            inc = inc + '\n' + line[7:line.index('.sh"')]
                        else:
                            inc = line[7:line.index('.sh"')]
                fIn.close()
                result = result + '\n"' + module + '","' + desc + '","' + dep.replace(' ', '\n') + '","' + inc + '"'
            except Exception as e:
                print('error for ' + file + '\n' + e)
                exit(1)

    fOut = open(rootPath + '/build_info_list.csv', 'w', encoding = "utf-8")
    fOut.write(result)
    fOut.close()
