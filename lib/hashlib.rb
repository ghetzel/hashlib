class Hash
  def diff(other)
    self.keys.inject({}) do |memo, key|
      unless self[key] == other[key]
        if other[key].is_a?(Hash)
          memo[key] = self[key].diff(other[key])
        else
          memo[key] = [self[key], other[key]]
        end
      end
      memo
    end
  end

  def get(path, default=nil)
    rget(path, default)
  end

  def set(path, value)
    rset(path, value)
  end

  def rget(path, default=nil)
    path = path.split('.') if path.is_a?(String)
    return default if path.nil? or path.empty?

  # arrayify all paths
    path = [*path]

    root = self.stringify_keys()
    key = path.first.to_s
    rest = path[1..-1]

    if root.has_key?(key)
      if root[key].is_a?(Hash)
        if rest.empty?
          return root[key]
        else
          return root[key].rget(rest, default)
        end
      elsif root[key].is_a?(Array) and root[key].first.is_a?(Hash)
        return root[key].collect{|v|
          v.rget(rest, default)
        }
      else
        return root[key]
      end
    else
      return default
    end
  end


  def rset(path, value, options={})
    path = path.split('.') if path.is_a?(String)
    return nil if path.nil? or path.empty?

  # arrayify all paths
    path = [*path]

    key = path.first.to_s
    rest = path[1..-1]

  # stringify the key we're processing
    if (self.has_key?(key.to_sym) rescue false)
      self[key] = self.delete(key.to_sym)
    end

    if rest.empty?
      if options[:delete_nil] === true and value.nil?
        self.delete(key)
      else
        self[key] = value
      end
    else
      if self[key].is_a?(Array) and self[key].first.is_a?(Hash)
      # set only on specific array items
        if options[:index]
          [*options[:index]].each do |i|
            self[key][i].rset(rest, value, options.reject{|k|
              k == :index
            }) unless self[key][i].nil?
          end

      # set path on all array items
        else
          self[key] = self[key].collect{|v|
            v.rset(rest, value, options)
          }.compact
        end
      else
        if not self[key].is_a?(Hash)
          self[key] = {}
        end

        self[key].rset(rest, value, options)
      end

    end

    self
  end

  def unset(path)
    rset(path, nil, {
      :delete_nil => true
    })
  end

  def rekey(from, to)
    value = get(from)
    unset(from)
    set(to, value)
  end

  def join(inner_delimiter, outer_delimiter=nil)
    outer_delimiter = inner_delimiter unless outer_delimiter
    self.to_a.collect{|i| i.join(inner_delimiter) }.join(outer_delimiter)
  end

  def coalesce(prefix=nil, base=nil, delimiter='_')
    base = self unless base
    rv = {}

    if base.is_a?(Hash)
      base.each do |k,v|
        if v
          base.coalesce(k,v,delimiter).each do |kk,vv|
            kk = (prefix.to_s+delimiter+kk.to_s) if prefix
            rv[kk.to_s] = vv
          end
        end
      end
    else
      rv[prefix.to_s] = base
    end

    rv
  end

  def each_recurse(options={}, &block)
    self.inject({}) do |h, (k, v)|
      path = [*options[:path]]+[k]
      h[k] = v

      if v.is_a?(Hash)
        if options[:intermediate] === true
          yield(k.to_s, v, path, h[k])
        end

        v.each_recurse(options.merge({
          :path => path
        }), &block)

      elsif v.is_a?(Array) and v.first.is_a?(Hash)
        v.each_index do |i|
          if v[i].is_a?(Hash)
            if options[:intermediate] === true
              yield(k.to_s, v[i], path, h[k][i], i)
            end

            v[i].each_recurse(options.merge({
              :path  => path,
              :index => i
            }), &block)
          end
        end

      else
        rv = yield(k.to_s, v, path, h, options[:index])
      end

      h
    end
  end

  def compact
    def _is_empty?(i)
      i === nil or (i.is_a?(String) and i.strip.chomp.empty?) or (i.respond_to?(:empty?) and i.empty?)
    end

    each_recurse do |k,v,path|
      path = path.join('.')

      if v.is_a?(Array)
        v.reject!{|i| _is_empty?(i) }
        unset(path) if v.empty?

      else
        unset(path) if _is_empty?(v)
      end

      nil
    end

    self
  end

  def stringify_keys()
    rv = {}
    each do |k, v|
      if v.is_a?(Hash)
        v = v.stringify_keys()
      elsif v.is_a?(Array)
        v = v.collect do |i|
          if i.is_a?(Hash)
            i.stringify_keys()
          else
            i
          end
        end
      end

      rv[k.to_s] = v
    end

    return rv
  end

  def symbolize_keys()
    rv = {}
    each do |k, v|
      if v.is_a?(Hash)
        v = v.symbolize_keys()
      elsif v.is_a?(Array)
        v = v.collect do |i|
          if i.is_a?(Hash)
            i.symbolize_keys()
          else
            i
          end
        end
      end

      rv[(k.to_sym rescue k)] = v
    end
    return rv
  end
end

class Array
  def count_distinct(group_by=[])
    rv = {}

    self.each do |i|
      if i.is_a?(Hash)
        components = group_by
        components = components.collect{|j| i.get(j) }
        components = [*components.first].product([*components.last])

        components.each do |component|
          path = []
          stack = []

          component.compact.each do |c|
            if c.is_a?(Array)
              path += [stack].product(c.flatten).collect{|i| i.flatten }
              stack = []
            else
              stack << c
            end
          end

          path = [component] if path.empty?

          path.each do |parts|
            parts[-1] = :null if parts[-1].nil?
            rv.set(parts, rv.get(parts, 0) + 1)
          end
        end
      end
    end


    sum_children = proc do |sum, key, value|
      if value.is_a?(Hash)
        sum += value.inject(0){|s,(k,v)| sum_children.call(s,k,v) }
      else
        sum += value
      end

      sum
    end

    populate = proc do |rv, key, value|
      i = ({
        :id    => ((key.empty? or key.nil? or key == 'null') ? nil : key),
        :count => (value.is_a?(Hash) ? value.inject(0){|s,(k,v)| sum_children.call(s,k,v) } : value)
      })

      i[:children] = value.inject([]){|s,(k,v)| populate.call(s,k,v) } if value.is_a?(Hash)
      rv << i
      rv
    end

    rv.inject([]){|s,(k,v)| populate.call(s,k,v) }
  end
end
