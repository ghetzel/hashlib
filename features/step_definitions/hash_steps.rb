Before do
  @hash = {}
end

Given /^I set a hash key ([\:]?)'(.*)' to equal '(.*)'$/ do |sym, key, value|
  @hash.set((sym == ':' ? key.to_sym : key), value)
end

Given /^I unset hash key ([\:]?)'(.*)'/ do |sym, key|
# set two values
  @hash.set((sym == ':' ? key.to_sym : key), Time.now)
  @hash.set("#{key}_test", Time.now)

# unset one
  @hash.unset(key)
end

Given /^I rekey the key ([\:]?)'(.*)' to ([\:]?)'(.*)'$/ do |oldsym, oldkey, newsym, newkey|
  @hash.set((oldsym == ':' ? oldkey.to_sym : oldkey), Time.now)
  @hash.rekey((oldsym == ':' ? oldkey.to_sym : oldkey), (newsym == ':' ? newkey.to_sym : newkey))
end


Then /^I should see the key ([\:]?)'(.*)' in the hash$/ do |sym, key|
  @hash.has_key?((sym == ':' ? key.to_sym : key))
end

Then /^I should not see the key ([\:]?)'(.*)' in the hash$/ do |sym, key|
  @hash.get((sym == ':' ? key.to_sym : key)).nil?
end

Then /^I should see a hash {([\:]?)'(.*)' => '(.*)'}$/ do |sym, key, value|
  @hash.should == {(sym == ':' ? key.to_sym : key) => value}
end

Then /^a get to ([\:]?)'(.*)' should equal '(.*)'$/ do |sym, key, value|
  @hash.get((sym == ':' ? key.to_sym : key)).should == value
end
