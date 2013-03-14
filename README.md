Hashlib: Utility methods for Ruby Hashes
========================================

Hashlib extends the base Ruby Hash class with new methods that offer useful functionality for working with hashes, specifically addressing handling of deeply-nested Hashes for representing rich object structures.

get
---

The get method is used to allow for retrieval of a deeply-nested value in a hash structure.

Given:

```ruby
config = {
  :global => {
    :security => {
      :sslroot => '/etc/ssl'
    },
    :pidfile => '/var/run/example.pid'
  },
  :plugins => ['logger', 'cruncher']
}
```

The following statements are equivalent:

```ruby
config.get('global.security.sslroot')

# returns the same thing as

config[:global][:security][:sslroot]
```

However, let's say you attempted to get <pre>config[:global][:adapters][:path]</pre>.  You would get a nasty NilError because <pre>:adapters</pre> doesn't exist.  However, if you used <pre>config.get('global.adapters.path')</pre>, the result would just be <pre>nil</pre>.  _get_ also takes a second argument that let's you specify the default value if the given path is not found.  This lets you very easily work with rich nested hashes while also specifying sane defaults for missing values.


set
---

The set method is the opposite of get.  It creates one or more intermediary hashes along a specified path and setting the value for the last component.

```ruby
y = {}
y.set('this.is.a.number', 4)

# results in
# {"this"=>{
#    "is"=>{
#      "a"=>{
#        "number"=>4
# }}}}

```
