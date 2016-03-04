# Fresh

[![Build Status](https://travis-ci.org/medols/fresh.svg)](https://travis-ci.org/medols/fresh) [![Code Climate](https://codeclimate.com/github/medols/fresh/badges/gpa.svg)](https://codeclimate.com/github/medols/fresh) [![Test Coverage](https://codeclimate.com/github/medols/fresh/badges/coverage.svg)](https://codeclimate.com/github/medols/fresh/coverage) [![Issue Count](https://codeclimate.com/github/medols/fresh/badges/issue_count.svg)](https://codeclimate.com/github/medols/fresh) [![Gem Version](https://badge.fury.io/rb/fresh-mc.svg)](https://badge.fury.io/rb/fresh-mc)

Fresh-mc is a ruby gem for exploring many-core programming with mpi.

### Installation

```shell
    $ gem install "fresh-mc"
```

### Usage

```ruby
    require 'fresh-mc'

    proc{
      3.times{|i|
        sleep rank
        puts "Hi #{i} from node #{rank}/#{size}"
        sleep 3-rank
      }
    }*3
```

### Docker container

1. **[Install docker](https://docs.docker.com/installation/)**.

    ```shell
    https://hub.docker.com/r/fresh/fresh
    ```

2. **Run an instance of the container**.

    ```shell
    $ docker run -it fresh/fresh
    ```

3. **Run your application**.

    ```shell
    $ echo "proc{ p sleep rank }*4" | docker run -i fresh/fresh
    ```

### Credits

    Copyright 2015-2016  Jaume Masip-Torne <jmasip@gianduia.net>
              2015-2016  Ismael Merodio-Codinachs <ismael@gianduia.net>

### Running the specs

First, resolve the fresh-mc gem dependencies:

```shell
    $ gem install rubinius-actor
```

Next, clone this repository:

```shell
    $ git clone https://github.com/medols/fresh.git
```

Then move to it:

```shell
    $ cd fresh
```

Clone [MSpec](http://github.com/ruby/mspec):

```shell
    $ git clone https://github.com/ruby/mspec.git ../mspec
```

And run the Fresh suite:

```shell
    $ ../mspec/bin/mspec
```

This will execute all the Fresh specs.

