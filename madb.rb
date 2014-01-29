#
# Android Cluster Toolkit - madb.rb
#
# shared implementation of multi-adb scripts
#
# (c) 2012-2014 Joshua J. Drake (jduck)
#

def plural(num)
  return "" if num == 1
  return "s"
end


def get_col_widths(include_serial = false)
  w_name = 0
  w_serial = 0

  $devices.each { |dev|
    next if dev[:disabled]

    l_name = dev[:name].length
    w_name = l_name if l_name > w_name

    if include_serial
      l_serial = dev[:serial].length
      w_serial = l_serial if l_serial > w_serial
    end
  }

  if include_serial
    return [ w_name, w_serial ]
  end
  return w_name
end


def print_col_prefix(include_serial, widths, dev)
  if include_serial
    w_name, w_serial = widths
    fmt = "[*] %#{w_name}s / %#{w_serial}s: "
    $stdout.write fmt % [ dev[:name], dev[:serial] ] 

  else
    fmt = "[*] %#{widths}s: "
    $stdout.write fmt % [ dev[:name] ]

  end
  $stdout.flush
end
 

