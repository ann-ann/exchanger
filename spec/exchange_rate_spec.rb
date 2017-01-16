require "spec_helper"

describe Exchanger::ExchangeRate do

  # I would rather create test database and use rand data generators for tests

  describe "#exchange" do
    it "shows rate for valid date" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-01-16")).to eq [110]
    end

    it "shows rate for multiple valid dates" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: ["1900-10-10", "1900-10-10"])).to eq([110, 110])
    end

    it "returns message if ecb rate missing" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2012-05-01")).to eq ["No rate for this date"]
    end

    it "returns message if date is in future" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2020-05-01")).to eq ["No rate for this date"]
    end

    it "returns rate of next working day if weekend" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-01-15")).to eq Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-01-16")
    end

    it "returs array with blank values if rates missing" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-10-13,2017-01-16,2017-10-13,2017-01-13".split(',')))
      .to eq ["No rate for this date", 110, "No rate for this date", 107]
    end

    context "invalid data formats" do
      it "ignores invalid date format" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "-jj")).to eq ["Invalid date passed"]

      end

    end
  end
end
