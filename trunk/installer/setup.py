#!/usr/bin/env python
'''
This is py2app/py2exe build script for videocity. It will automatically ensure that build dependencies are
available via ez_setup. 

Windows:  python setup.py py2exe
Mac OS X: python setup.py py2app
'''

import ez_setup
ez_setup.use_setuptools()

import sys, os, glob
from setuptools import setup

mainscript = ['../python/videocity.py']

def recurse(actual, pseudo):
    fnames = filter(lambda x: x != '.svn', os.listdir(actual))
    dnames = filter(lambda y: os.path.isdir(y[1]), map(lambda x: (x, actual + '/' +  x), fnames))
    pnames = filter(lambda y: os.path.isfile(y), map(lambda x: actual + '/' +  x, fnames))
    result = [(pseudo, [x]) for x in pnames]
    for name, path in dnames:
        result += recurse(path, pseudo + '/' + name)
    return result

DATA_FILES = [('', ['../LICENSING', '../README'])]
DATA_FILES += recurse('../data', 'data') + recurse('../www', 'www')

print 'data-files are\n' + '\n'.join(map(lambda x: str(x[0]) + ': ' + str(x[1]), DATA_FILES))

if sys.platform == 'darwin':
    # Cross-platform applications generally expect sys.argv to be used for opening files.
    extra_options = dict(setup_requires = ['py2app'], app=mainscript, options=dict(py2app=dict(argv_emulation=True)), data_files=DATA_FILES,)
elif sys.platform == 'win32':
    import py2exe
    extra_options = dict(setup_requires=['py2exe'], windows=mainscript, data_files=DATA_FILES, )
else:
     # Normally unix-like platforms will use "setup.py install" and install the main script as such
     extra_options = dict(scripts=mainscript, data_files=DATA_FILES, )

setup(name="videocity", **extra_options)

