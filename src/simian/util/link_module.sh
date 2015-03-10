#!/bin/bash
#
# Copyright 2011 Google Inc. All Rights Reserved.

set -e

GAE_BUNDLE=gae_bundle/

function find_module() {
  python <<EOF
import imp
try:
  print imp.find_module('$1')[1]
except ImportError:
  pass
EOF
}

function find_sitepackage_module() {
  python <<EOF
import os
import re
try:
  user_paths = os.environ['PYTHONPATH'].split(os.pathsep)
except KeyError:
  user_paths = []

pymod = '$1'
for path in user_paths:
  for f in os.listdir(path):
    if re.search(r'(' + pymod + ')', os.path.join(path, f), re.I):
      print os.path.join(path, f)
EOF
}

function find_egg_file() {
  egg=$(find . -type f -maxdepth 1 -name ${module}-*.egg 2>/dev/null)
  if [[ ! -z "${egg}" ]]; then
    echo "${egg}"
  fi

  egg=$(find .eggs -type f -maxdepth 1 -name ${module}-*.egg 2>/dev/null)
  if [[ ! -z "${egg}" ]]; then
    echo "${egg}"
  fi
}

function find_egg_dir() {
  egg=$(find . -type d -name ${module}-*.egg 2>/dev/null)
  if [[ ! -z "${egg}" ]]; then
    find "${egg}" -type d -maxdepth 1 -mindepth 1 \! -name EGG-INFO
  fi
}

function link_module() {
  local module="$1"

  local egg=$(find_egg_file ${module})
  if [[ ! -z "${egg}" ]]; then
    unzip -o "${egg}" -d "${GAE_BUNDLE}" > /dev/null
    rm -rf "${GAE_BUNDLE}/EGG-INFO"
    return
  fi

  local egg=$(find_egg_dir ${module})
  if [[ ! -z "${egg}" ]]; then
    cp -fR "${egg}" "${GAE_BUNDLE}"
    return
  fi

  local path=$(find_module ${module})
  if [[ ! -z "${path}" ]]; then
    rm -f "${GAE_BUNDLE}/${module}"
    ln -s "${path}" "${GAE_BUNDLE}/${module}"
    return
  fi

  local path=$(find_sitepackage_module ${module})
  if [[ ! -z "${path}" ]]; then
    rm -f "${GAE_BUNDLE}/${module}"
    ln -s "${path}" "${GAE_BUNDLE}/${module}"
    return
  fi

  echo "ERROR: path not found for ${module}. symlink creation failure."
  exit 1
}

link_module "$1"
