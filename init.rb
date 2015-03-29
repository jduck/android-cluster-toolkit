#!/usr/bin/env ruby

#
# Android Cluster Toolkit
# 
# init.rb - generate devices/pool.rb based on 'adb devices'
#
# (c) 2012-2015 Joshua J. Drake (jduck)
#

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.join(File.dirname(bfn), 'lib'))


# get a list of devices via 'adb devices'
require 'madb'
new = adb_scan(true)


device_pool = File.join(File.dirname(bfn), 'lib', 'devices', 'pool.rb')
if File.exists? device_pool
  $stderr.puts "[!] devices/pool.rb exists! rm it to start over"
  exit(1)
end


template = nil
File.open("#{device_pool}.sample", 'rb') { |f|
  template = f.read
}

File.open(device_pool, 'wb') { |f|
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
