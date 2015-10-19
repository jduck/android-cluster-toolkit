#!/usr/bin/env ruby

#
# Android Cluster Toolkit
#
# scan.rb - scan for new android devices (not in $devices)
#
# (c) 2012-2015 Joshua J. Drake (jduck)
#

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.join(File.dirname(bfn), 'lib'))


# load connected set of devices
require 'devices'
load_connected(true)

# get a list of devices via 'adb devices'
require 'madb'
adb_devices = adb_scan(true)


# intersect this with $devices
new_devices = []
adb_devices.each { |port,serial|
  found = false
  $devices[:connected].each { |dev|
    if dev[:serial] == serial
      found = true
      break
    end
  }

  new_devices << [ port, serial ] if not found
}

$stderr.puts "[*] Found #{new_devices.length} new device#{plural(new_devices.length)}!"


# print any new ones in the format used to add to devices-orig.rb
new_devices.each { |port,serial|
  puts %Q|
  {
    :name => 'name', # description
    :serial => '#{serial}',
  },
|
}
