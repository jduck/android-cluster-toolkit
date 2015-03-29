#!/usr/bin/env ruby

#
# Android Cluster Toolkit
#
# shell.rb - spawn a shell for the specified device
#
# (c) 2012-2015 Joshua J. Drake (jduck)
#

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.join(File.dirname(bfn), 'lib'))


require 'devices'


devid = parse_device_arg("shell")
load_connected()
dev = get_one_device(devid)


puts "[*] starting shell for #{dev[:name]} (ANDROID_SERIAL=\"#{dev[:serial]}\") ..."
ENV["ANDROID_SERIAL"] = dev[:serial]
ENV["debian_chroot"] = dev[:name]

system(ENV['SHELL']) #, '--norc')
