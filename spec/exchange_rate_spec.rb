require "spec_helper"

describe Exchanger::ExchangeRate do

  subject { Exchanger::ExchangeRate.create(date: Date.today.to_s, rate: 1.1) }

  describe "#exchange" do
    it "shows rate for valid date" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: Date.today.to_s)).to eq [110]
    end
  end
end
