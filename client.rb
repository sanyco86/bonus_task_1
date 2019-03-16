require 'openssl'
require 'faraday'
require 'concurrent'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# config: OVERHEAT_LIMITS = { a: 3, b: 2, c: 1 }.freeze
THREAD_POOL_A = Concurrent::FixedThreadPool.new(3)
THREAD_POOL_B = Concurrent::FixedThreadPool.new(2)
THREAD_POOL_C = Concurrent::FixedThreadPool.new(1)

# Есть три типа эндпоинтов API
# Тип A:
#   - работает 1 секунду
#   - одновременно можно запускать не более трёх
# Тип B:
#   - работает 2 секунды
#   - одновременно можно запускать не более двух
# Тип C:
#   - работает 1 секунду
#   - одновременно можно запускать не более одного

def a(value)
  Concurrent::Promises.future_on(THREAD_POOL_A) do
    Faraday.get("https://localhost:9292/a?value=#{value}").body
  end
end

def b(value)
  Concurrent::Promises.future_on(THREAD_POOL_B) do
    Faraday.get("https://localhost:9292/b?value=#{value}").body
  end
end

def c(value)
  Concurrent::Promises.future_on(THREAD_POOL_C) do
    Faraday.get("https://localhost:9292/c?value=#{value}").body
  end
end

# Референсное решение, приведённое ниже работает правильно, занимает ~19.5 секунд
# Надо сделать в пределах 7 секунд

def c_result(array)
  Concurrent::Promises.zip(*array).then do |*aaa, b|
    c("#{collect_sorted(aaa)}-#{b}")
  end.flat
end

def collect_sorted(arr)
  arr.sort.join('-')
end

def work
  c1 = c_result([a(11), a(12), a(13), b(1)])
  c2 = c_result([a(21), a(22), a(23), b(2)])
  c3 = c_result([a(31), a(32), a(33), b(3)])

  c123 = Concurrent::Promises.zip(c1, c2, c3).then { |*ccc| a(collect_sorted(ccc)) }.flat

  result = c123.value!

  puts "RESULT = #{result}"

  puts "RESULT TEST FAILED!!!\nExpected: 0bbe9ecf251ef4131dd43e1600742cfb\nGot:#{result}" if result != "0bbe9ecf251ef4131dd43e1600742cfb"
end
