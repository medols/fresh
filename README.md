# Fresh

[![Build Status](https://travis-ci.org/medols/fresh.svg)](https://travis-ci.org/medols/fresh)

[![Code Climate](https://codeclimate.com/repos/5661cb3f8ba8e52f200008d6/badges/40edd1dd4d705726b2a3/gpa.svg)](https://codeclimate.com/repos/5661cb3f8ba8e52f200008d6/feed)

[![Test Coverage](https://codeclimate.com/repos/5661cb3f8ba8e52f200008d6/badges/40edd1dd4d705726b2a3/coverage.svg)](https://codeclimate.com/repos/5661cb3f8ba8e52f200008d6/coverage)

[![Issue Count](https://codeclimate.com/repos/5661cb3f8ba8e52f200008d6/badges/40edd1dd4d705726b2a3/issue_count.svg)](https://codeclimate.com/repos/5661cb3f8ba8e52f200008d6/feed)

Fresh is a ruby gem.

### Installation

    $ gem install "fresh"

### Usage

    require 'fresh'

    fresh [
      proc{|id,all|
        7.times{|i|
          puts "Iter #{i+1} from node #{id+1} of #{all} nodes"
          sleep 1
        }
      },
      proc{|id,all|
        7.times{|i|
          sleep 0.5 
          puts "Iter #{i+1} from node #{id+1} of #{all} nodes"
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

