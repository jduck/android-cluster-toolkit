#!/usr/bin/env ruby

#
# Android Cluster Toolkit
# 
# reconfig.rb - generate devices.rb based on 'adb devices' and 'devices-orig.rb'
#
# (c) 2012-2015 Joshua J. Drake (jduck)
#

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.join(File.dirname(bfn), 'lib'))

require 'madb'

$verbose = true if ARGV.pop == "-v"

# load connected set of devices
require 'devices'
load_connected(true)
$old_devices = $devices[:connected].dup

# load total device pool
load_pool(true)

# get a list of devices via 'adb devices'
adb_devices = adb_scan(true)


def find_device(pool, serial)
  pool.each { |dev|
    if dev[:serial] == serial
      return dev
    end
  }
  nil
end


# determine new set and missing devices
if $verbose
  # The following will evolve into devices that are no longer connected,
  # but are in the pool.
  missing = $devices[:pool].dup
end
new_devices = []          # new available devices
nconn = []                # newly connected
dconn = $old_devices.dup  # recently disconnected
adb_devices.each { |ser|
  # find this device in the pool of all supported devices
  dev = find_device($devices[:pool], ser)
  if dev
    # got it.
    new_devices << dev

    # it's not missing.
    missing.delete dev if $verbose
  end

  # see if this one was present before...
  pdev = find_device($old_devices, ser)

  # if so, it didn't disconnect :)
  if pdev
    dconn.delete pdev
  elsif dev
    # if we have a device, it's new.
    nconn << dev
  end
}


# show status. which matched, what's new, what disappeared...
$stderr.puts "[*] Matched #{new_devices.length} device#{plural(new_devices.length)}!"
$stderr.puts "  #{nconn.length} device#{plural(nconn.length)} added"
nconn.each { |dev|
  $stderr.puts "    #{dev[:name]} (#{dev[:serial]})"
}
$stderr.puts "  #{dconn.length} device#{plural(dconn.length)} removed"
dconn.each { |dev|
  $stderr.puts "    #{dev[:name]} (#{dev[:serial]})"
}


# show messing devices (verbose only)
if $verbose
  $stderr.puts "[*] Missing #{missing.length} device#{plural(missing.length)}:"
  missing.each { |dev|
    $stderr.puts "    #{dev[:name]} (#{dev[:serial]})"
  }
end


# produce a new devices.rb with the currently connected devices only
devices = File.join(File.dirname(bfn), 'lib', 'devices', 'connected.rb')

File.open(devices, "wb") { |f|
  f.puts "$devices[:connected] = ["
  new_devices.each { |dev|
    name = "'#{dev[:name]}',"
    serial = "'#{dev[:serial]}',"

    line = "  { :name => %-16s :serial => %-24s" % [name, serial]
    if dev[:codename]
      line << ":codename => #{dev[:codename].inspect}"
    end
    line << " },"

    f.puts line
  }
  f.puts "]"
}
