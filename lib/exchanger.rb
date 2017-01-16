require "exchanger/version"
require "exchanger/exchange_rate"
require "pry"

module Exchanger
  def self.exchange(amount, dates)
    ExchangeRate.seed
    ExchangeRate.exchange(amount: amount, dates: dates.split(','))
  end
end
