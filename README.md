# Exchanger

Gem for exchanging USD to EUROs using ECB rates:



  https://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A


  It fetches csv data and stores to local sqllite db

## Installation

Add this line to your application's Gemfile:

  gem 'currency_exchanger'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install currency_exchanger

## Usage

  You can test it just from terminal after gem installed. Example:


    $ ./exe/exchanger AMOUNT DATES_SEPARATED_BY_COMMA


    $ ./exe/exchanger 100 2017-01-16


  Example of gem using:

  Exchanger.exchange(100, Date.today)


    => 109.94


  Exchanger.exchange(100, [Date.yesterday, Date.today])


    => [109.94, 110.02]


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ann-ann/exchanger.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

