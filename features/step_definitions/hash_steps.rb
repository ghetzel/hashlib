Before do
  @hash = {}
  @results = nil

  @test_hashes = {
    :elastichash => {
      "took" => 1,
      "timed_out" => false,
      "_shards" => {
        "total" => 5,
        "successful" => 5,
        "failed" => 0
    },

    "hits" => {
        "total"=>1967,
        "max_score"=>1.0,
        "hits"=>[]
    },

    "facets" => {
      "counts"=> {
        "_type"=>"terms",
        "missing"=>2,
        "total"=>1965,
        "other"=>0,
        "terms"=> [{
          "term"=>"online", "count"=>1311},
          {"term"=>"allocatable", "count"=>637},
          {"term"=>"installing", "count"=>17}]
        }
      }
    }
  }
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

Given /^I get the key ([\:]?)'(.*)' from (.*)$/ do |sym, key, hash|
  @results = @test_hashes[hash.to_sym].rget((sym == ':' ? key.to_sym : key))
end



Then /^I should see the key ([\:]?)'(.*)' in the hash$/ do |sym, key|
  @hash.has_key?((sym == ':' ? key.to_sym : key)).nil?.should == false
end

Then /^I should not see the key ([\:]?)'(.*)' in the hash$/ do |sym, key|
  @hash.get((sym == ':' ? key.to_sym : key)).nil?.should == true
end

Then /^I should see a hash {([\:]?)'(.*)' => '(.*)'}$/ do |sym, key, value|
  @hash.should == {(sym == ':' ? key.to_sym : key) => value}
end

Then /^a get to ([\:]?)'(.*)' should equal '(.*)'$/ do |sym, key, value|
  @hash.get((sym == ':' ? key.to_sym : key)).should == value
end

Then /^I should see a (.*) of length (\d+) in the results$/ do |klass, count|
  @results.is_a?(Kernel.const_get(klass)).should == true
  @results.respond_to?(:length).should == true
  @results.length.should == count.to_i
end

Then /^I should see the array \[(.*)\] in the results$/ do |values|
  @results.is_a?(Array).should == true
  (@results - values.split(/,\s*/)).empty?.should == true
end
