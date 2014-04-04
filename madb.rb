#
# Android Cluster Toolkit - madb.rb
#
# shared implementation of multi-adb scripts
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

require 'open3'
require 'getoptlong'


def plural(num)
  return "" if num == 1
  return "s"
end


#
# set globals based on the command line options
#
def parse_global_options()
  opts = GetoptLong.new(
      [ '--one-line', '-1', GetoptLong::NO_ARGUMENT ],
      [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ],
      [ '--device', '-d', GetoptLong::REQUIRED_ARGUMENT ]
    )

  opts.each { |opt, arg|
    case opt
      when '--one-line'
        $one_line = true
      when '--verbose'
        $verbose = true
      when '--device'
        return false if arg == "--"

        $selected_devices = arg.split(',')
        $do_all = ($selected_devices.first == ".")
        opts.terminate()
      else
        return false
    end
  }

  if $one_line
    $widths = get_col_widths()
  end

  return true
end


#
# return if the specified device is selected
#
def is_selected(dev)
  return true if $do_all

  sel = $selected_devices
  return false if not sel

  if sel.length > 0 and (sel.include? dev[:name] or sel.include? dev[:serial])
    return true
  end
  return false
end


#
# return widths for columns to align columnar output
#
def get_col_widths()
  w_name = 0
  w_serial = 0

  $devices.each { |dev|
    next if dev[:disabled]
    next if not is_selected(dev)

    l_name = dev[:name].length
    w_name = l_name if l_name > w_name

    if $verbose
      l_serial = dev[:serial].length
      w_serial = l_serial if l_serial > w_serial
    end
  }

  if $verbose
    return [ w_name, w_serial ]
  end
  return w_name
end


#
# print the line prefix for single device
#
def print_col_prefix(dev)
  if $verbose
    if $widths
      w_name, w_serial = $widths
      w_serial *= -1
    else
      w_name = w_serial = ''
    end
    fmt = "[*] %#{w_name}s / %#{w_serial}s: "
    $stdout.write fmt % [ dev[:name], dev[:serial] ] 

  else
    fmt = "[*] %#{$widths}s: "
    $stdout.write fmt % [ dev[:name] ]

  end
  $stdout.flush
end


#
# get a list of devices via 'adb devices'
#
def adb_scan()
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

  return adb_devices
end


#
# run an adb command, capture and return the lines of output
#
# NOTE: this is not interactive!
#
def adb_get_lines(incmd)
  adb_devices = []

  lines = []

  cmd = [ 'adb' ]
  cmd += incmd
  Open3.popen3(*cmd) { |sin, sout, serr, thr|
    pid = thr[:pid]
    outlines = sout.readlines
    errlines = serr.readlines

    if errlines.length > 0
      lines << "ERROR:"
      errlines.each { |ln|
        lines << ln
      }
    end

    outlines.each { |ln|
      lines << ln.chomp
    }
  }

  return lines
end


#
# run the adb binary once for each selected device
# each time, specifying the remaining ARGV
#
def multi_adb(base = nil)

  $devices.each { |dev|

    # skip this device if it wasn't selected
    next if not is_selected(dev)

    if dev[:disabled]
      puts "[!] Warning: The selected device is marked disabled. It may not be present."
    end

    if $one_line
      print_col_prefix(dev)

      args = [ '-s', dev[:serial] ]
      args += base if base
      args += ARGV
      puts adb_get_lines(args).join("\\n")

    else
      print_col_prefix(dev)
      puts ""

      cmd = [ 'adb', '-s', dev[:serial] ]
      cmd += base if base
      cmd += ARGV
      system(*cmd)
      puts ""
    end
  }

end

