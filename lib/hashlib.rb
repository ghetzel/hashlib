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
    root = self

    begin
      path = path.to_s.split('.') unless path.is_a?(Array)

      path.each do |key|
        key = key.to_s

        if root.is_a?(Array)
          rv = nil

          root.each do |r|
            if r.has_key?(key)
              rv = r[key]
              break
            end
          end

          root = rv
        else
          root = (root[key] rescue nil)
        end
      end

      return (root.nil? ? default : root)
    rescue NoMethodError
      return default
    end
  end

  def set(path, value)
    if not path.is_a?(Array)
      path = path.to_s.strip.split(/[\/\.]/)
    end
    root = self

    path[0..-2].each do |p|
      root[p.to_s] = {} unless root[p.to_s].is_a?(Hash)
      root = root[p.to_s]
    end

    if value.nil?
      root.reject!{|k,v| k.to_s == path.last.to_s }
    else
      root[path.last.to_s] = value
    end

    self
  end

  def unset(path)
    set(path, nil)
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

  def each_recurse(root=self, path=[], inplace=false, &block)
    root.each do |k,v|
      path << k

      if v.is_a?(Hash)
        each_recurse(v, path, &block)
      else
        rv = yield(k, v, path)
        root[k] = rv if inplace === true
      end

      path.pop
    end
  end

  def each_recurse!(root=self, path=[], &block)
    each_recurse(root, path, true, &block)
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
end

class Array
  def count_distinct(group_by=[])
    rv = {}

    self.each do |i|
      if i.is_a?(Hash)
        components = group_by
        components = components.collect{|j| i.get(j) }
        path = []
        stack = []

        components.compact.each do |c|
          if c.is_a?(Array)
            path += [stack].product(c.flatten).collect{|i| i.flatten }
            stack = []
          else
            stack << c
          end
        end

        path = [components] if path.empty?

        path.each do |parts|
          parts[-1] = :null if parts[-1].nil?
          rv.set(parts, rv.get(parts, 0) + 1)
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