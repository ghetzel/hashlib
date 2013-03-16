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

  def find(path, default=nil)
    root = self

    begin
      if not path.is_a?(Array)
        path = path.to_s.strip.scan(/[a-z0-9\@\_\-\+]+(?:\[[^\]]+\])?/).to_a
      end

      path.each do |p|
        x, key, subfield, subvalue = p.to_s.split(/([a-z0-9\@\_\-\+]+)(?:\[([^=]+)(?:=(.+))?\])?/i)
        root = (root[key.to_s] rescue nil)
        #puts key, root.inspect

        if subfield and root.is_a?(Array)
          root.each do |r|
            if r.is_a?(Hash) and r[subfield.to_s] and ( (subvalue && r[subfield.to_s].to_s == subvalue) || true)
              root = r
              break
            end
          end
        end
      end

      return (root.nil? ? default : root)
    rescue NoMethodError
      return default
    end
  end

  def set(path, value)
    if not path.is_a?(Array)
      path = path.strip.split(/[\/\.]/)
    end
    root = self

    path[0..-2].each do |p|
      root[p.to_s] = {} unless root[p.to_s].is_a?(Hash)
      root = root[p.to_s]
    end

    if value
      root[path.last.to_s] = value
    else
      root.reject!{|k,v| k.to_s == path.last.to_s }
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

  def each_recurse(root=self, path=[], &block)
    root.each do |k,v|
      path << k

      if v.is_a?(Hash)
        each_recurse(v, path, &block)
      else
        yield(k, v, path)
      end

      path.pop
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
    end

    self
  end
end