$KCODE = "Shift_JIS"
require 'jcode'

while line = gets
  print line.gsub(/\s:\s��(.+?)([����])/){%Q[\s:\s��<��#$1>#$2]}
end
