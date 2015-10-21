require 'plural'

$devices = {
  :pool => [],
  :connected => [],
}



def load_connected(verbose = false)
  begin
    require 'devices/connected'
  rescue LoadError
    $stderr.puts "[!] WARNING: Unable to load connected devices! Did you run reconfig.rb?"
  end

  if verbose
    devs = $devices[:connected]
    $stderr.puts "[*] Loaded #{devs.length} device#{plural(devs)} from 'devices/connected'"
  end
end


def load_pool(verbose = false)
  begin
    require 'devices/pool'
  rescue LoadError
    $stderr.puts "[!] Unable to load the device pool! Did you run init.rb or scan.rb?"
  end

  if verbose
    devs = $devices[:pool]
    $stderr.puts "[*] Loaded #{devs.length} device#{plural(devs)} from 'devices/pool'"
  end
end


def parse_device_arg(cmd)
  devid = nil
  if ARGV.length > 0
    devid = ARGV.shift
  end

  if devid.nil?
    $stderr.puts "usage: #{cmd} <device name or serial>"
    exit(1)
  end

  return devid
end


def get_one_device(devid)
  if $devices[:connected].length < 1
    load_connected()
  end

  usedev = nil
  $devices[:connected].each { |dev|
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

  return usedev
end


# build the environment vars to set...
def get_device_envs(dev)
  envs = { "ANDROID_SERIAL" => dev[:serial] }
  envs.merge!("ANDROID_ADB_SERVER_PORT" => dev[:port].to_s)
  return envs
end

# build a string to display for the device env vars
def get_device_env_str(envs)
  envstr = ''
  envs.each { |k,v|
    envstr << ' ' if envstr.length > 0
    envstr << "#{k}=\"#{v}\""
  }
  return envstr
end
