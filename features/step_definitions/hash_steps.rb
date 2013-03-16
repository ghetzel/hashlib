Before do
  @hash = {}
end

Given /^I set a hash key '(.*)' to equal '(.*)'$/ do |key, value|
  @hash.set(key, value)
end

Given /^I unset hash key '(.*)'/ do |key|
# set two values
  @hash.set(key, Time.now)
  @hash.set("#{key}_test", Time.now)

# unset one
  @hash.unset(key)
end

Given /^I rekey the key '(.*)' to '(.*)'$/ do |oldkey, newkey|
  @hash.set(oldkey, Time.now)

  @hash.rekey(oldkey, newkey)
end


Then /^I should see the key '(.*)' in the hash$/ do |key|
  @hash.has_key?(key)
end

Then /^I should not see the key '(.*)' in the hash$/ do |key|
  not @hash.has_key?(key)
end

Then /^I should see a hash {'(.*)' => '(.*)'}$/ do |key, value|
  @hash.should == {key => value}
end

Then /^a get to '(.*)' should equal '(.*)'$/ do |key, value|
  @hash.get(key).should == value
end
