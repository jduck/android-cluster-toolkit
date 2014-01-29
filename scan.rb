#!/usr/bin/env ruby

#
# Android Cluster Toolkit
#
# scan.rb - scan for new android devices (not in $devices)
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

require 'open3'

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.dirname(bfn))

require 'devices'
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


# print any new ones in the format used to add to devices.rb
new.each { |ser|
    puts "  {"
    puts "    :name => 'name', # description"
    puts "    :serial => '#{ser}',"
    puts "    :usb => 'MFGR:CODE', # adb"
    puts "  },"
}

