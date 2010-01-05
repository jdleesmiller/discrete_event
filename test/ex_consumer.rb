require 'discrete_event'

module DiscreteEvent
  module Example
    #
    # A simple example for testing: consumes and records a set number ({#limit})
    # of random numbers at random intervals.
    #
    class Consumer < DiscreteEvent::Simulation
      attr_reader :consumed, :limit

      def initialize limit, start_time = 0.0
        super(start_time)
        @consumed = []
        @limit = limit
      end

      def reset
        consumed.clear
        super
      end

      def consume
        after rand do 
          consumed << now
          consume
        end if consumed.size < limit
      end

      def start
        consume
      end
    end
  end
end
