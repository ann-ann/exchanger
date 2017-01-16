require "spec_helper"

describe Exchanger do

  describe "#exchange" do
    it "returns exhanges" do
      expect(Exchanger.exchange(100,"1900-10-10,1900-10-10")).to eq([110, 110])
    end
  end
end
