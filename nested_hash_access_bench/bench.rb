require 'benchmark'

# Benchmark for my improved version of irbrocks' nil verif nested hashes
#  https://github.com/irbrocks/blog-sources/tree/master/reduce-nil-verifications-nested-hashes


#
# Check if a hash constains the path of keys.
#
# Example:
# h = { a: { b: { c: 1 }}}
#
# hash_value h, :a, :b              # { c: 1 }
# hash_value h, :a, :b, :c          # 1
# hash_value h, :a, :b, :d          # nil
# hash_value h, :a, :d              # nil
# hash_value h, :a, :d, :c          # nil
# hash_value h, :a, :b, :c, :d      # nil
#
# == Parameters:
# hash::
#   Hash to check.
# keys::
#   Array with the sequence of keys to get value
#
# == Returns:
# Value of the key in the hash or nil
#
module Original

  def self.hash_value(hash, *keys)
    if hash[keys.first] && keys.size == 1
      return hash[keys.first]
    elsif hash[keys.first] && hash[keys.first].is_a?(Hash)
      hash_value(hash[keys.first], *keys[1..keys.size-1])
    else
      return nil
    end
  end

end


module Enhanced

  # faster just by accessing hash value by key only once
  def self.hash_value(hash, *keys)
    val = hash[keys.first]
    if val
      return val if keys.size == 1
      if val.is_a?(Hash)
        return hash_value(val, *keys[1..keys.size-1])
      end
    end
    return nil
  end

end


module Refactored

  # Almost speed x2
  #  mostly won by using only one array for keys without spread/unspread
  def self.hash_value(hash, *keys)
    hash_value_rec(hash, keys)
  end

  private
  def self.hash_value_rec(hash, keys, idx = 0)
    return hash if idx >= keys.size
    return nil unless hash.is_a?(Hash)
    return hash_value_rec(hash[keys[idx]], keys, idx.next)
  end

end


NB_ITER = 1_000_000
H = { a: { b: { c: 1 }}}.freeze

Benchmark.bmbm do |x|

  x.report('Traditionnal') do
    NB_ITER.times do
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:b]
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:b].is_a?(Hash) && H[:a][:b][:c]
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:b].is_a?(Hash) && H[:a][:b][:c]
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:b].is_a?(Hash) && H[:a][:b][:d]
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:d]
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:d].is_a?(Hash) && H[:a][:d][:c]
      H.is_a?(Hash) && H[:a].is_a?(Hash) && H[:a][:b].is_a?(Hash) && H[:a][:b][:c].is_a?(Hash) && H[:a][:b][:c][:d]
    end
  end

  x.report('Original') do
    NB_ITER.times do
      Original::hash_value(H, :a, :b)
      Original::hash_value(H, :a, :b, :c)
      Original::hash_value(H, :a, :b, :d)
      Original::hash_value(H, :a, :d)
      Original::hash_value(H, :a, :d, :c)
      Original::hash_value(H, :a, :b, :c, :d)
    end
  end

  x.report('Enhanced') do
    NB_ITER.times do
      Enhanced::hash_value(H, :a, :b)
      Enhanced::hash_value(H, :a, :b, :c)
      Enhanced::hash_value(H, :a, :b, :d)
      Enhanced::hash_value(H, :a, :d)
      Enhanced::hash_value(H, :a, :d, :c)
      Enhanced::hash_value(H, :a, :b, :c, :d)
    end
  end

  x.report('Refactored') do
    NB_ITER.times do
      Refactored::hash_value(H, :a, :b)
      Refactored::hash_value(H, :a, :b, :c)
      Refactored::hash_value(H, :a, :b, :d)
      Refactored::hash_value(H, :a, :d)
      Refactored::hash_value(H, :a, :d, :c)
      Refactored::hash_value(H, :a, :b, :c, :d)
    end
  end

  # Just for experience, remove all unnessecary ".is_a?(Hash)" checks
  x.report('Traditionnal without checks') do
    NB_ITER.times do
      H && H[:a] && H[:a][:b]
      H && H[:a] && H[:a][:b] && H[:a][:b][:c]
      H && H[:a] && H[:a][:b] && H[:a][:b][:c]
      H && H[:a] && H[:a][:b] && H[:a][:b][:d]
      H && H[:a] && H[:a][:d]
      H && H[:a] && H[:a][:d] && H[:a][:d][:c]
      H && H[:a] && H[:a][:b] && H[:a][:b][:c].is_a?(Hash) && H[:a][:b][:c][:d]
    end
  end

end


# Bench results for 1M iterations (i7 3632QM)
#
# Rehearsal ---------------------------------------------------------------
# Traditionnal                  1.540000   0.010000   1.550000 (  1.545846)
# Original                      6.800000   0.000000   6.800000 (  6.796547)
# Enhanced                      5.110000   0.000000   5.110000 (  5.099906)
# Refactored                    3.730000   0.000000   3.730000 (  3.725016)
# Traditionnal without checks   1.160000   0.000000   1.160000 (  1.157271)
# ----------------------------------------------------- total: 18.350000sec

#                                   user     system      total        real
# Traditionnal                  1.550000   0.000000   1.550000 (  1.550960)
# Original                      6.840000   0.000000   6.840000 (  6.832495)
# Enhanced                      5.120000   0.000000   5.120000 (  5.116133)
# Refactored                    3.710000   0.000000   3.710000 (  3.713973)
# Traditionnal without checks   1.170000   0.000000   1.170000 (  1.164000)
