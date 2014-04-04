#!/usr/bin/env ruby

#
# Android Cluster Toolkit
# 
# init.rb - generate devices-orig.rb based on 'adb devices'
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

require 'open3'

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.dirname(bfn))


# get a list of devices via 'adb devices'
require 'madb'
new = adb_scan()

$stderr.puts "[*] Found #{new.length} device#{plural(new.length)}!"

if File.exists? 'devices-orig.rb'
  $stderr.puts "[!] devices-orig.rb exists! rm it to start over"
  exit(1)
end

template = nil
File.open('devices-orig.rb.sample', 'rb') { |f|
  template = f.read
}

File.open('devices-orig.rb', 'wb') { |f|
  f.puts template.split(/^=end$/).first + "=end"
  new.each { |dev|
    f.puts %Q|
  {
    :name => 'name', # description
    :serial => '#{dev}',
  },
|
    #f.puts "{ :name => 'set me', :serial => '#{dev}' },"
  }
  f.puts "]"
}


