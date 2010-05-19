module DiscreteEvent
  #
  # A simulation, including and event queue, current time, and various helpers.
  #
  # There are two key terms:
  # * action: any Ruby block
  # * event: an action to be executed at some specified time in the future
  # Events are usually created using the {#at} and {#after} methods.
  # The methods {#at_each_index}, {#every} and {#recur_after} make some
  # important special cases more efficient.
  #
  # See the {file:README} for an example.
  #
  # Typically, you will want to inherit from this class to construct a
  # simulation of your own. However, you can also use it as a standalone event
  # queue.
  #
  class Simulation
    #
    # Event queue entry for events; you do not need to use this class directly.
    #
    Event = Struct.new(:time, :action)

    # Current time (taken from the currently executing event, if any).
    # @return [Number]
    attr_reader :now

    # Event queue.
    # @return [PQueue]
    attr_reader :events
    protected :events

    def initialize start_time=0.0
      @start_time = start_time
      @now = start_time
      @events = PQueue.new {|a,b| a.time < b.time}
      @recur_interval = nil
    end

    # Schedule +action+ (a block) to run at the given +time+.
    #
    # @param [Number] time at which +action+ should run; must be >= {#now}
    # @yield [] action to be run at +time+
    # @return [nil]
    def at time, &action
      raise "cannot schedule event in the past" if time < now
      @events.push(Event.new(time, action))
      nil
    end

    # Schedule +action+ (a block) to run after the given +delay+ (with respect
    # to {#now}).
    #
    # @param [Number] delay after which +action+ should run; non-negative
    # @yield [] action to be run after +delay+
    # @return [nil]
    def after delay, &action
      at(@now + delay, &action)
    end

    # Schedule +action+ (a block) to run at each time in +times+; the index
    # into times is given to the +action+ block.
    #
    # This method may be of interest if you have a large number of events that
    # occur at known times. You could use {#at} to add each one to the event
    # queue at the start of the simulation, but this will make adding other
    # events more expensive. Instead, this method adds them one at a time, so
    # only the next event is stored in the event queue.
    #
    # @example
    #   Alert = Struct.new(:when, :message)
    #   alerts = [Alert.new(12, "ha!"), Alert.new(42, "ah!")] # and many more
    #   at_each_index alerts.map{|a| a.when} do |i|
    #     puts alerts[i].message
    #   end
    # 
    # @param [Array<Numeric>] times to yield at; must be non-decreasing; you
    #                         will usually want +times+ to stay the same for the
    #                         duration of the simulation (pass a copy if you
    #                         plan to change the original object).
    # @param [Fixnum] i start at this index in +times+
    # @return [nil]
    def at_each_index times, index=0, &action
      return nil unless times[index]
      at times[index] do
        yield(index)
        at_each_index(times, index+1, &action)
      end
      nil
    end

    # When called from within an action block, repeats the action block after
    # the specified +interval+ has elapsed.
    #
    # Calling this method from outside an action block has no effect.
    # You may call this method at most once in an action block.
    #
    # @example
    #   at 5 do
    #     puts "now: #{now}"
    #     recur_after 10*rand
    #   end
    #
    # Note that you can achieve the same effect using {#at} and {#after} and a
    # named method, as in
    #   def demo
    #     at 5 do
    #       puts "now: #{now}"
    #       after 10*rand do
    #         demo
    #       end
    #     end
    #   end
    # but it is somewhat more efficient to call +recur_after+, and, if you do,
    # the named method is not necessary.
    #
    # @param [Numeric] interval non-negative
    # @return [nil]
    def recur_after interval
      raise "cannot recur twice" if @recur_interval
      @recur_interval = interval
      nil
    end

    # Schedule +action+ (a block) to run periodically.
    #
    # This is useful for statistics collection.
    #
    # Note that if you specify one or more events of this kind, the simulation
    # will never run out of events, so you have to manually stop it (usually by
    # throwing <tt>:stop</tt>).
    #
    # @example
    #   every 5 do
    #     if now > 100
    #       # record stats
    #     end
    #     throw :stop if now > 1000
    #   end
    #
    # @param [Numeric] interval non-negative
    # @param [Numeric] start block first runs at this time
    # @return [nil]
    def every interval, start=0, &action
      at start do
        action.call
        recur_after interval
      end
      nil
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
    #
    # @abstract
    def start
    end

    #
    # Run the action for the next event in the queue.
    #
    # @yield [] after the event (if any) runs
    # @return [Boolean] false if there are no more events.
    #
    def update &block
      event = @events.top
      return false unless event

      # Perform the action.
      @now = event.time
      event.action.call

      # Recurring events get special treatment: can avoid doing a push and a pop
      # by reusing the Event at the top of the heap, but with a new time. Note
      # that this code is wrong if there is a new top element in the heap, but
      # this should not be possible.
      if @recur_interval
        event.time = @now + @recur_interval
        @events.replace_top(event)
        @recur_interval = nil
      else
        @events.pop
      end

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

