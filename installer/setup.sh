#! /usr/bin/env bash

# build the installer for Mac OS X

export PYTHONPATH=../../p2p-sip/src:../../rtmplite:../python:.
python setup.py py2app

