#!/usr/bin/env python

import os
import argparse
import xml.etree.ElementTree as ET

TOOL_SHEDS_XML = os.path.join(os.environ['GALAXY_ROOT'], "config/tool_sheds_conf.xml")
TOOL_SHEDS_XML_SAMPLE = TOOL_SHEDS_XML + '.sample'

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Add new Tool Shed to Galaxy.')
    parser.add_argument('-n', '--name', help='Tool Shed name that is displayed in the admin menue')
    parser.add_argument('-u', '--url', help='Tool Shed URL')

    args = parser.parse_args()

    ts = ET.Element('tool_shed')
    ts.set('name', args.name)
    ts.set('url', args.url)

    if os.path.exists( TOOL_SHEDS_XML ):
        tree = ET.parse( TOOL_SHEDS_XML )
    else:
        tree = ET.parse( TOOL_SHEDS_XML_SAMPLE )
    root = tree.getroot()
    root.append( ts )
    tree.write( TOOL_SHEDS_XML )
