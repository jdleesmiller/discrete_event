module DiscreteEvent
  #
  # A simulation, including and event queue, current time, and various helpers.
  #
  # There are two key terms:
  # * action: any Ruby block
  # * event: an action to be executed at some specified time in the future
  # Events are created using the {#at} and {#after} methods. 
  #
  # Typically, you will want to inherit from this class to construct a
  # simulation of your own. However, you can also use it as a standalone event
  # queue.
  #
  class Simulation
    # @private
    Event = Struct.new(:time, :action)
    class Event
      def > rhs; self.time < rhs.time end
    end

    # Current time; from the currently executing event.
    # @return [Number]
    attr_reader :now

    # Event queue; usually, you shouldn't change this.
    # @return [PQueue]
    attr_reader :events

    def initialize start_time=0.0
      @start_time = start_time
      @now = start_time
      @events = PQueue.new
    end

    # Schedule +action+ (a block) to run at the given +time+.
    #
    # @param [Number] time at which +action+ should run; must be >= #{now}
    # @yield [] action to be run at +time+
    # @return [nil]
    def at time, &action
      raise "cannot schedule event in the past" if time < now
      @events.push(Event.new(time, action))
      nil
    end

    # Schedule +action+ (a block) to run after the given +delay+ (with respect
    # to {#now}).
    # @param [Number] delay after which +action+ should run; non-negative
    # @yield [] action to be run after +delay+
    # @return [nil]
    def after delay, &action
      at(@now + delay, &action)
    end

    # Clear any pending events in the event queue and reset {#now}.
    # You may want to override this, if you want to reset your
    # simulation-specific state, as well.
    #
    # @return [self]
    def reset
      @now = @start_time
      @events.clear
      self
    end

    # Called by +run+ when beginning a new simulation; you will probably want
    # to override this.
    # @abstract
    def start
    end

    #
    # Run the action for the next event in the queue.
    #
    # @yield [] after the event (if any) runs
    # @return [Boolean] false if there are no more steps.
    #
    def update &block
      event = @events.pop
      return false unless event
      @now = event.time
      event.action.call
      block.call if block_given?
      return true
    end

    #
    # Run (or continue, if there are existing events) the simulation until 
    # +:stop+ is thrown, or there are no more events.
    #
    # @yield [] after each event runs 
    # @return [nil]
    #
    def run &block
      start if @events.empty?
      catch :stop do
        nil while update(&block)
      end
    end
  end
end

