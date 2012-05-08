require 'discrete_event'

module DiscreteEvent
  module Example
    #
    # A simple example for testing: consumes and records a set number ({#limit})
    # of random numbers at random intervals.
    #
    class ConsumerSim < DiscreteEvent::Simulation
      attr_reader :consumed, :limit

      def initialize limit, now = 0.0
        super(now)
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

    #
    # A consumer that can participate in a simulation with a {Producer} (i.e.
    # share the same clock and event queue).
    #
    class Consumer
      include Events

      def initialize event_queue
        @event_queue = event_queue
        @objects = []
        @consumed = []
      end

      attr_reader :consumed

      def consume object
        after rand do
          @consumed << object
        end
      end

      attr_reader :event_queue
    end

    #
    # See {Consumer}.
    #
    class Producer
      include Events

      def initialize event_queue, objects, consumer
        @event_queue = event_queue
        @objects = objects
        @consumer = consumer
      end

      def produce
        unless @objects.empty?
          after rand do 
            @consumer.consume @objects.shift
            produce
          end
        end
      end

      private

      attr_reader :event_queue
    end
  end
end

