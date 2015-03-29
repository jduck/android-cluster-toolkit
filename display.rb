#!/usr/bin/env ruby

#
# Android Cluster Toolkit
#
# display.rb - list which android devices are plugged in
# (in both $devices[:connected] and adb_devices)
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


# show devices in both sets
$verbose = true
$devices.each { |dev|
  adb_devices.each { |ser|
    if dev[:serial] == ser
      puts "    #{dev[:name]} / #{dev[:serial]}"
      break
    end
  }
}
