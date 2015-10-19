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


# build the environment vars to set...
envs = get_device_envs(dev)
envstr = get_device_env_str(envs)

# show!
puts "[*] starting shell for #{dev[:name]} (#{envstr}) ..."

# add one final var and apply them.
envs.merge!("debian_chroot" => dev[:name])
envs.each { |k,v| ENV[k] = v }

# spawn the shell!
system(ENV['SHELL']) #, '--norc')
