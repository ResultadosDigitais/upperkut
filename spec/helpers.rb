require 'time'

module Helpers
  def travel_to(time)
    allow(Time).to receive(:now).and_return(time)
  end
end

