# Fresh

[![Build Status](https://travis-ci.org/medols/fresh.svg)](https://travis-ci.org/medols/fresh)

[![Code Climate](https://codeclimate.com/github/medols/fresh/badges/gpa.svg)](https://codeclimate.com/github/medols/fresh)

[![Test Coverage](https://codeclimate.com/github/medols/fresh/badges/coverage.svg)](https://codeclimate.com/github/medols/fresh/coverage)

[![Issue Count](https://codeclimate.com/github/medols/fresh/badges/issue_count.svg)](https://codeclimate.com/github/medols/fresh)

Fresh is a ruby gem.

### Installation

    $ gem install "fresh"

### Usage

    require 'fresh'

    fresh [
      proc{|rank,size|
        7.times{|i|
          puts "Iter #{i+1} from node #{rank+1} of #{size} nodes"
          sleep 1
        }
      },
      proc{|rank,size|
        7.times{|i|
          sleep 0.5 
          puts "Iter #{i+1} from node #{rank+1} of #{size} nodes"
          sleep 0.5 
        }
      }
    ]

### Contribution

### Credits

    Copyright 2015  Jaume Masip-Torne <jmasip@gianduia.net>
              2015  Ismael Merodio-Codinachs <ismael@gianduia.net>

### Running the specs

First, clone this repository:

    $ git clone https://github.com/medols/fresh.git

Then move to it:

    $ cd fresh

Clone [MSpec](http://github.com/ruby/mspec):

    $ git clone https://github.com/ruby/mspec.git ../mspec

And run the Fresh suite:

    $ ../mspec/bin/mspec

This will execute all the Fresh specs.

