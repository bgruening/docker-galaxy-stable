#!/usr/bin/env python

# This script retrieves the url for downloading a tarball archive for the active submodule at
# the path
# https://github.com/bgruening/docker-galaxy-stable/tree/dev/galaxy/roles/galaxyprojectdotorg.galaxyextras

# For more information on github api see https://developer.github.com/v3/repos/contents/

__author__ = "Lukas Voegtle"
__email__ = "voegtlel@tf.uni-freiburg.de"

import urllib.request, json, sys

if len(sys.argv) != 2:
  print("Usage:", sys.argv[0], "ref")
  print("  ref: The name of the commit/branch/tag. (e.g. \"master\")")
  sys.exit(0)

url = "https://api.github.com/repos/bgruening/docker-galaxy-stable/contents/galaxy/roles/galaxyprojectdotorg.galaxyextras?ref=" + sys.argv[1]
with urllib.request.urlopen(url) as response:
  data = json.loads(response.read().decode(response.info().get_param('charset') or 'utf-8'))
print(data['_links']['git'].replace('/git/trees/', '/tarball/'))
