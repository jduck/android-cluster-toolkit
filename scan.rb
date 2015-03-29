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


# load current devices
require 'devices'
$stderr.puts "[*] Loaded #{$devices.length} device#{plural($devices.length)} from 'devices.rb'"

# get a list of devices via 'adb devices'
require 'madb'
adb_devices = adb_scan(true)


# intersect this with $devices
new = []
adb_devices.each { |ser|
  found = false
  $devices.each { |dev|
    if dev[:serial] == ser
      found = true
      break
    end
  }

  new << ser if not found
}

$stderr.puts "[*] Found #{new.length} new device#{plural(new.length)}!"


# print any new ones in the format used to add to devices-orig.rb
new.each { |ser|
  puts %Q|
  {
    :name => 'name', # description
    :serial => '#{ser}',
  },
|
}
