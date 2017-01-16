require "active_record"
require "csv"
require "open-uri"

ActiveRecord::Base.logger = Logger.new(STDERR)

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "/tmp/exchanger.sqlite3"
)

ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.tables.include? "exchange_rates"
    create_table :exchange_rates do |t|
      t.date :date, null: false, index: true
      t.decimal :rate, scale: 2, precision: 8
    end
  end
end

module Exchanger
  class ExchangeRate < ActiveRecord::Base
    DATA_SOURCE = "https://sdw.ecb.europa.eu/quickviewexport.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A&type=csv".freeze
    DATE_NORMALIZER = lambda { |date| Date.parse(date) rescue nil }

    validates :date, uniqueness: true, presence: true
    validates :rate, numericality: { greater_than: 0 }, presence: true

    class << self
      private

      # Determine previous or next business day
      def skip_weekends(date, inc)
        while date.on_weekend? do
          date += inc
        end
        date
      end
    end

    # Seeds database with exchange rates from ECB.
    #
    # As per https://www.ecb.europa.eu/stats/exchange/eurofxref/html/index.en.html, the reference rates are usually
    # updated around 16:00 CET on every working day, except on TARGET closing days (holidays like Christmas).
    # They are based on a regular daily concertation procedure between central banks across Europe, which normally
    # takes place at 14:15 CET(but updates arounf 16pm)
    #
    # We implement simplest possible caching based on ECD data update rules mentioned above.
    def self.seed
      last_available_record = ExchangeRate.order(:date).last

      if (last_available_record&.date == skip_weekends(Date.today.in_time_zone('Berlin').to_date, -1)) && Time.now.in_time_zone('Berlin').hour >= 16
        return
      end
      encoded_url = URI.encode(DATA_SOURCE)
      data = open(URI.parse(encoded_url)).read

      CSV.parse(data)[5..-1].each do |date, rate|
        next if rate == '-'
        ExchangeRate.find_or_create_by(date: date, rate: rate.to_f)
      end
    end

    def self.exchange(amount:, dates:)
      amount = amount.to_f
      dates = [*dates].map(&DATE_NORMALIZER)

      dates.map do |date|
        if date
          if rate_record = ExchangeRate.where(date: date).first
            # Regular business day, we have all the data.
            (rate_record.rate * amount).to_f
          elsif date.on_weekend? && next_business_day = skip_weekends(date.in_time_zone('Berlin').to_date, 1)
            # Weekends. When you send exchange request on a weekend, it will be exchanges on the next business day.
            # Note that this is in CET timezone as per ECB rules. Sorry, no luck exchanging on Moday from Sydney.

            # I wish I knew but I really don't
            return nil if next_business_day.future?

              rate_record = ExchangeRate.where(date: next_business_day).first
              (rate_record.rate * amount).to_f
          else
            # Sorry, don't know why you couldn't exchange euros on 2012-05-01. Sometimes ECB doesn't have data.
            # Also handles dates that are in future.
            "No rate for this date"
          end
        else
          "Invalid date passed"
        end
      end
    end
  end
end
