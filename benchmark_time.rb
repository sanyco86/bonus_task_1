require 'benchmark'
require_relative 'client'

time = Benchmark.measure do
  work
end

puts "TIME: #{time}"
# before TIME: 0.082696   0.017866   0.100562 ( 19.225027)
# need   TIME: ~7 sec
# TIME:   0.119266   0.018523   0.137789 (  6.140968)
