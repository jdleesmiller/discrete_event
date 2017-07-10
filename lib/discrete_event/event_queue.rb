# frozen_string_literal: true
module DiscreteEvent
  #
  # Queue of pending events; also keeps track of the clock (the current time).
  #
  # There are two key terms:
  # * action: any Ruby block
  # * event: an action to be executed at some specified time in the future
  # Events are usually created using the {#at} and {#after} methods.
  # The methods {#at_each}, {#every} and {#recur_after} make some important
  # special cases more efficient.
  #
  # See the {file:README} for an example.
  #
  class EventQueue
    #
    # Event queue entry for events.
    #
    Event = Struct.new(:time, :action)

    #
    # Current time (taken from the currently executing event, if any). You can
    # use floating point or integer time.
    #
    # @return [Numeric]
    #
    attr_reader :now

    #
    # Event queue.
    #
    # @return [PQueue]
    #
    attr_reader :events

    def initialize(now=0.0)
      @now = now
      @events = PQueue.new {|a,b| a.time < b.time}
      @recur_interval = nil
    end

    #
    # Schedule +action+ (a block) to run at the given +time+; +time+ must not be
    # in the past.
    #
    # @param [Numeric] time at which +action+ should run; must be >= {#now}
    #
    # @yield [] action to be run at +time+
    #
    # @return [Event]
    #
    def at(time, &action)
      raise "cannot schedule event in the past" if time < now
      event = Event.new(time, action)
      @events.push(event)
      event
    end

    #
    # Schedule +action+ (a block) to run after the given +delay+ (with respect
    # to {#now}).
    #
    # @param [Numeric] delay after which +action+ should run; non-negative
    #
    # @yield [] action to be run after +delay+
    #
    # @return [Event]
    #
    def after(delay, &action)
      at(@now + delay, &action)
    end

    #
    # Cancel an event previously created with {#at} or {#after}.
    #
    # @param [Event] event the event to cancel
    #
    # @return [nil]
    #
    def cancel(event)
      # not very efficient but hopefully not used very often
      temp = []
      until @events.empty? || @events.top.time > event.time
        e = @events.pop
        break if e.equal?(event)
        temp << e
      end
      temp.each do |e|
        @events.push(e)
      end
      nil
    end

    #
    # Schedule +action+ (a block) to run for each element in the given list
    # (possibly at different times).
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
    #   at_each alerts, :when do |alert|
    #     puts alert.message
    #   end
    #
    # @param [Enumerable] elements to yield; must be in ascending order
    #        according to +time+; note that this method keeps a reference to
    #        this object and removes elements as they are executed, so you may
    #        want to pass a copy if you plan to change it after this call
    #        returns
    #
    # @param [Proc, Symbol, nil] time used to determine when the action will run
    #        for a given element; if a +Proc+, the proc must return the
    #        appropriate time; if a +Symbol+, each element must respond to
    #        +time+; if nil, it is assumed that <tt>element.time</tt> returns
    #        the time
    #
    # @yield [element]
    #
    # @yieldparam [Object] element from +elements+
    #
    # @return [nil]
    #
    def at_each(elements, time=nil, &action)
      raise ArgumentError, 'no action given' unless block_given?

      unless elements.empty?
        element = elements.shift
        if time.nil?
          element_time = element.time
        elsif time.is_a? Proc
          element_time = time.call(element)
        elsif time.is_a? Symbol
          element_time = element.send(time)
        else
          raise ArgumentError, "bad time"
        end

        at element_time do
          yield element
          at_each elements, time, &action
        end
      end
      nil
    end

    #
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
    #
    # @return [nil]
    #
    def recur_after(interval)
      raise "cannot recur twice" if @recur_interval
      @recur_interval = interval
      nil
    end

    #
    # Schedule +action+ (a block) to run periodically.
    #
    # This is useful for statistics collection.
    #
    # Note that if you specify one or more events of this kind, the simulation
    # will never run out of events.
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
    #
    # @param [Numeric] start block first runs at this time
    #
    # @return [nil]
    #
    def every(interval, start=0, &action)
      at start do
        yield
        recur_after interval
      end
      nil
    end

    #
    # The time of the next queued event, or +nil+ if there are no queued events.
    #
    # If this method is called from within an action block, it returns {#now}
    # (that is, the current event hasn't finished yet, so it's still in some
    # sense the next event).
    #
    # @return [Numeric, nil]
    #
    def next_event_time
      event = @events.top
      if event
        event.time
      else
        nil
      end
    end

    #
    # Run the action for the next event in the queue.
    #
    # @return [Boolean] false if there are no more events.
    #
    def run_next
      event = @events.pop
      if event
        # run the action
        @now = event.time
        event.action.call

        # Handle recurring events.
        if @recur_interval
          event.time = @now + @recur_interval
          @events.push(event)
          @recur_interval = nil
        end

        true
      else
        false
      end
    end

    #
    # Run events until the given time (inclusive). When this method returns,
    # {#now} is +time+, and all events scheduled to run at times up to and
    # including +time+ have been run.
    #
    # @param [Numeric] time to run to (inclusive)
    #
    # @return [nil]
    #
    def run_to(time)
      # add an event to ensure that we actually stop at the given time, even if
      # there isn't an event in the queue
      at time do
        # nothing
      end
      run_next until @events.empty? || next_event_time > time
      nil
    end

    #
    # Allow for the creation of a ruby +Enumerator+ for the simulation. This
    # yields for each event. Note that this enumerator may return infinitely
    # many events, if there are repeating events ({#every}).
    #
    # @example
    #   eq = EventQueue.new
    #   eq.at 13 do
    #     puts "hi"
    #   end
    #   eq.at 42 do
    #     puts "hello"
    #   end
    #   for t in eq.to_enum
    #     puts t
    #   end
    #
    # @yield [now] called immediately after each event runs
    #
    # @yieldparam [Numeric] now as {#now}
    #
    # @return [self]
    #
    def each
      yield now while run_next
      self
    end

    #
    # Clear any pending events in the event queue and reset {#now}.
    #
    # @return [self]
    #
    def reset(now=0.0)
      @now = now
      @events.clear
      self
    end
  end
end
