# DottedHash

Recursive OpenStruct-like or Hash-like object. Uses ActiveModel.

Based on *Tire::Result::Item* with addition of writing attributes and security limits.

## Installation

Add this line to your application's Gemfile:

    gem 'dotted_hash'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dotted_hash

## Usage

### Create

    > DottedHash.new(id: 'duke', content: "Why I'm so great")

    > document = DottedHash.new(id: 'duke', content: "Why I'm so great",
      quotes: { 
        'Duke Nukem Forever' => ['Always bet on Duke!', 'Hail to the King, baby!'],
        'Manhattan Project' => ['Confucius say... DIE!', 'Crouching mutant, hidden pipebomb!'] }
      )
    => <DottedHash id: "duke", content: "Why I'm so great", quotes: <DottedHash Duke Nukem Forever:
    ["Always bet on Duke!", "Hail to the King, baby!"], Manhattan Project: ["Confucius say... DIE!", "Crouching mutant, hidden pipebomb!"]>>

### Read

    > document.content
    => "Why I'm so great"

if key has spaces

    > document.quotes['Duke Nukem Forever']
    > document.quotes['Duke Nukem Forever']

nested

    > documents.authors.creator.name
   
### Write

    > document.name = 'Duke Nukem'
    > document.quotes = ["I've got balls of steel.", 'Who wants some?']

recursively (also creates sub-DottedHashes if they don't exist)

    > document.recursive_assign('authors.creator.name', 'Duke Nukem')

### Delete

    > document.name = nil

### Get document in nice form

    > document.to_hash
    > document.to_json

### Deceive class name based on *_type* attribute if using *Rails* (if class exists)

    > d = DottedHash.new(_type: 'cannon', name: 'BFG')
    > d.class
    => Cannon

## Set security for structure

- *MAX_DEPTH* for maximal depth of whole tree (keys_depth+1), counted from 0.
While it is not completely bulletproof, because depth can be set to wrong number if careless, it is enough in most of the time.

- *MAX_ATTRS* to specify maximum count of attributes. Use integer for limit to all levels or use hash like this

    MAX_ATTRS = {1 => 20, 2 => 5, default: 10}

for limits to be applied to certain levels. *Default* is optional, if not present - limit is not set.

- *MAX_SIZE* to limit structure size. Size is computed from JSON representation of *DottedHash*.
Note that some objects may have much bigger representation in memory than in JSON.


## JSON

Because security uses JSON representation of DottedHash, use library like *Oj* or *Yajl* when under heavy load.

DottedHash uses *ActiveSupport* which uses *MultiJson*...

Which backend is used?

    > MultiJson.adapter

or

    > ActiveSupport::JSON.backend

Set backend

    > MultiJson.adapter = :oj

or

    > ActiveSupport::JSON.backend = :yajl



See source and tests for some more details.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## About

Original project: [https://github.com/karmi/tire](https://github.com/karmi/tire)

Author of modificated version: *Ivan Stana*

License: *MIT*
