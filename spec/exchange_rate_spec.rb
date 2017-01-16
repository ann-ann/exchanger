require "spec_helper"

describe Exchanger::ExchangeRate do
  # I would rather create test database and use rand data generators for tests
  # and shoulds-matchers to validate active record model
  context "validations" do
  # I will not create test for saving valid exchande_rate record because there is no test database
    subject { Exchanger::ExchangeRate.new(date: Date.today, rate: 1.1) }
    it "validates date present" do
      subject.date = nil
      subject.valid?
      expect(subject.errors[:date]).to include("can't be blank")
    end

    it "validates date is uniq" do
      subject.date = Exchanger::ExchangeRate.send(:skip_weekends, 10.days.ago.to_date, 1)
      subject.valid?
      expect(subject.errors[:date]).to include("has already been taken")
    end

    it "validates rate present" do
      subject.rate = nil
      subject.valid?
      expect(subject.errors[:rate]).to include("can't be blank")
    end

    it "validates rate is greater than o" do
      subject.rate = 0
      subject.valid?
      expect(subject.errors[:rate]).to include("must be greater than 0")
    end
  end

  describe "#seed" do
    it "updates database if todays data is missing" do
      Exchanger::ExchangeRate.order(:date).last.destroy
      expect{Exchanger::ExchangeRate.seed}.to change{Exchanger::ExchangeRate.count}.by(1)
    end

    it "ignores database update if todays data present and today is not weekend" do
      last_record = Exchanger::ExchangeRate.order(:date).last
      Exchanger::ExchangeRate.seed
      expect(last_record).to eq Exchanger::ExchangeRate.order(:date).last
    end
  end

  describe "#skip_weekends" do
    it "skips Sunday and returns Monday" do
      expect(Exchanger::ExchangeRate.send(:skip_weekends, Date.parse("2017-01-15"), 1)).to eq Date.parse("2017-01-16")
    end

    it "skips Saturday and returns Monday" do
      expect(Exchanger::ExchangeRate.send(:skip_weekends, Date.parse("2017-01-14"), 1)).to eq Date.parse("2017-01-16")
    end

    it "ignores date if its working day" do
      expect(Exchanger::ExchangeRate.send(:skip_weekends, Date.parse("2017-01-16"), 1)).to eq Date.parse("2017-01-16")
    end
  end

  describe "#exchange" do
    it "shows rate for valid date" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-01-13")).to eq [107]
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
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-01-08")).to eq Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-01-09")
    end

    it "returs array with messages if rates missing" do
      expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "2017-10-13,2017-01-09,2017-10-13,2017-01-13".split(',')))
      .to eq ["No rate for this date", 105, "No rate for this date", 107]
    end

    context "invalid data formats" do
      it "ignores invalid date format" do
        expect(Exchanger::ExchangeRate.exchange(amount: 100, dates: "-jj")).to eq ["Invalid date passed"]
      end

      it "ignores invalid amount to exchange" do
        expect(Exchanger::ExchangeRate.exchange(amount: "test", dates: "2017-01-09")).to eq [0.0]
      end
    end
  end
end
