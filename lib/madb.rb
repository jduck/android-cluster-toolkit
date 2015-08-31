#
# Android Cluster Toolkit - madb.rb
#
# shared implementation of multi-adb scripts
#
# (c) 2012-2015 Joshua J. Drake (jduck)
#

require 'open3'
require 'getoptlong'

require 'plural'


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
        $do_all = false
        if $selected_devices.length == 0
          $do_all = true
        elsif $selected_devices.first == "."
          $do_all = true
          discard = $selected_devices.shift
        end

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
# return the selection (regex) that matches the provided device
#
def which_matches(sel, dev)
  # regex match :)
  sel.each { |str|
    return str if dev[:name] =~ /^#{str}$/
  }
  return nil
end

#
# return if the specified device is selected
#
def is_selected(dev)
  return true if $do_all

  sel = $selected_devices
  return false if not sel or sel.length == 0

  if (sel.include? dev[:name] or sel.include? dev[:serial])
    return true
  end

  # regex match :)
  str = which_matches(sel, dev)
  return true if not str.nil?

  return false
end


#
# return widths for columns to align columnar output
#
def get_col_widths()
  w_name = 0
  w_serial = 0

  $devices[:connected].each { |dev|
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
    return [ w_name, w_serial + 1 ]
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
def adb_scan(verbose = false)
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
      ln.strip!
      next if ln.length < 1
      next if ln == "List of devices attached"

      parts = ln.split("\t")
      serial = parts.first
      adb_devices << serial
    }
  }

  if verbose
    $stderr.puts "[*] Found #{adb_devices.length} device#{plural(adb_devices.length)} via 'adb devices'"
  end

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
def multi_adb(base = nil, argv = nil)

  not_found = []
  not_found = $selected_devices.dup if $selected_devices

  $devices[:connected].each { |dev|

    # skip this device if it wasn't selected
    next if not is_selected(dev)

    # it was selected, remove it from the "not_found" list
    sel = which_matches(not_found, dev)
    if not sel.nil?
      not_found.delete sel
    else
      not_found.delete dev[:name]
      not_found.delete dev[:serial]
    end

    argv ||= ARGV

    if dev[:disabled]
      puts "[!] Warning: The selected device is marked disabled. It may not be present."
    end

    if $one_line
      print_col_prefix(dev)

      args = [ '-s', dev[:serial] ]
      args += base if base
      args += argv
      puts adb_get_lines(args).join("\\n")

    else
      print_col_prefix(dev)
      puts ""

      cmd = [ 'adb', '-s', dev[:serial] ]
      cmd += base if base
      cmd += argv
      system(*cmd)
      puts ""
    end
  }

  not_found.each { |sel|
    puts "[!] didn't find device \"#{sel}\" - typo? device not connected?"
  }

end

