Feature: Hash Patches
  Scenario: Test Key Manipulation Methods
    Given I set a hash key 'test' to equal 'value'
    Then I should see a hash {'test' => 'value'}

    Given I set a hash key 'test.deep' to equal 'value2'
    Then a get to 'test.deep' should equal 'value2'

    Given I unset hash key 'bye'
    Then I should not see the key 'bye' in the hash

    Given I rekey the key 'old' to 'new'
    Then I should see the key 'new' in the hash
    Then I should not see the key 'old' in the hash

  Scenario: Test Symbol->String Key Handling
    Given I set a hash key :'test' to equal 'value'
    Then I should see a hash {'test' => 'value'}

    Given I unset hash key :'bye'
    Then I should not see the key 'bye' in the hash
    Then I should not see the key :'bye' in the hash

    Given I rekey the key :'old' to :'new'
    Then I should see the key 'new' in the hash
    Then I should see the key :'new' in the hash
    Then I should not see the key 'old' in the hash
    Then I should not see the key :'old' in the hash


  Scenario: Test Various Hashes
    Given I get the key 'insanely.unlikely.key' from elastichash with default 'nope'
    Then I should see the value 'nope' in the results

    Given I get the key 'insanely.unlikely.key' from elastichash with default :'auto'
    Then I should see the value :'auto' in the results

    Given I get the key 'facets.counts.terms' from elastichash
    Then I should see a Array of length 3 in the results

    Given I get the key 'facets.counts.terms.term' from elastichash
    Then I should see the array [online,allocatable,installing] in the results

