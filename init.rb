#!/usr/bin/env ruby

#
# Android Cluster Toolkit
# 
# init.rb - generate devices-orig.rb based on 'adb devices'
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.join(File.dirname(bfn), 'lib'))


# get a list of devices via 'adb devices'
require 'madb'
new = adb_scan()
$stderr.puts "[*] Found #{new.length} device#{plural(new.length)} via 'adb devices'"


orig_devices = File.join(File.dirname(bfn), 'lib', 'devices-orig.rb')

if File.exists? orig_devices
  $stderr.puts "[!] devices-orig.rb exists! rm it to start over"
  exit(1)
end

template = nil
File.open("#{orig_devices}.sample", 'rb') { |f|
  template = f.read
}

File.open(orig_devices, 'wb') { |f|
  f.puts template.split(/^=end$/).first + "=end"
  new.each { |dev|
    f.puts %Q|
  {
    :name => 'name', # description
    :serial => '#{dev}',
  },
|
  }
  f.puts "]"
}


