#!/usr/bin/env ruby

#
# Android Cluster Toolkit
# 
# reconfig.rb - generate devices.rb based on 'adb devices' and 'devices-orig.rb'
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

require 'open3'

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.dirname(bfn))

require 'devices-orig'
$stderr.puts "[*] Loaded #{$devices.length} devices from our database"

require 'madb'


# get a list of devices via 'adb devices'
adb_devices = []
cmd = [ 'adb', 'devices' ]
Open3.popen3(*cmd) { |sin, sout, serr, thr|
  pid = thr[:pid]
  outlines = sout.readlines
  errlines = serr.readlines

  if errlines.length > 0
    $stderr.puts "ERROR:"

    errlines.each { |ln|
      $stderr.puts ln
    }
  end

  outlines.each { |ln|
    ln.chomp!
    next if ln.length < 1
    next if ln == "List of devices attached "

    parts = ln.split("\t")
    serial = parts.first
    adb_devices << serial
  }
}

$stderr.puts "[*] Found #{adb_devices.length} devices via 'adb devices'"


# print missing devices and store found ones
missing = $devices.dup
new = []
adb_devices.each { |ser|
  $devices.each { |dev|
    if dev[:serial] == ser
      new << dev
      missing.delete dev
      break
    end
  }
}


$stderr.puts "[*] Found #{new.length} device#{plural(new.length)}!"

$stderr.puts "[*] Missing #{missing.length} device#{plural(missing.length)}:"
missing.each { |dev|
  $stderr.puts "    #{dev[:name]} (#{dev[:serial]})"
}


# produce a new devices.rb with the currently connected devices only
devices = File.join(File.dirname(bfn), 'devices.rb')

File.open(devices, "wb") { |f|
  f.puts "$devices = ["
  new.each { |dev|
    name = "'#{dev[:name]}',"
    serial = "'#{dev[:serial]}',"
    usb = "'#{dev[:usb]}',"
    codename = ""
    codename = ":codename => '#{dev[:codename]}'," if dev[:codename]

    f.puts "  { :name => %-16s :serial => %-24s :usb => %-10s %s }," % [name, serial, usb, codename]
  }
  f.puts "]"
}

