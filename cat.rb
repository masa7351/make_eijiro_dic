$KCODE = "Shift_JIS"

while line = ARGF.gets
  next if line.strip.empty?
  print line
end
