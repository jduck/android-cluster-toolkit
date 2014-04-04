#!/usr/bin/env ruby

#
# Android Cluster Toolkit
#
# shell.rb - spawn a shell for the specified device
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

bfn = __FILE__
while File.symlink?(bfn)
  bfn = File.expand_path(File.readlink(bfn), File.dirname(bfn))
end
$:.unshift(File.join(File.dirname(bfn), 'lib'))

require 'devices'


devid = nil
if ARGV.length > 0
  devid = ARGV.shift
end

if devid.nil?
  $stderr.puts "usage: shell <device name or serial>"
  exit(1)
end


usedev = nil
$devices.each { |dev|
  if dev[:name] == devid or dev[:serial] == devid
    usedev = dev
    break
  end
}

if usedev.nil?
  $stderr.puts "[!] unable to find device: #{devid}"
  exit(1)
end

if usedev[:disabled]
  puts "[!] Warning: The selected device is marked disabled. It may not be present."
end


puts "[*] starting shell for #{usedev[:name]} (ANDROID_SERIAL=\"#{usedev[:serial]}\") ..."
ENV["ANDROID_SERIAL"] = usedev[:serial]
ENV["debian_chroot"] = usedev[:name]

system(ENV['SHELL']) #, '--norc')

