module DiscreteEvent
  #
  # Mix-in for simulations with multiple objects that have to share the same
  # clock. See the {file:README} for an example.
  #
  # The implementing class must have an instance method <tt>event_queue</tt>
  # that returns the {EventQueue} to use; this method may be private.
  #
  module Events
    #
    # See {EventQueue#at}.
    #
    # @param [Number] time at which +action+ should run; must be >= {#now}
    #
    # @yield [] action to be run at +time+
    #
    # @return [nil]
    #
    def at time, &action
      event_queue.at(time, &action)
    end

    #
    # See {EventQueue#after}.
    #
    # @param [Number] delay after which +action+ should run; non-negative
    #
    # @yield [] action to be run after +delay+
    #
    # @return [nil]
    #
    def after delay, &action
      event_queue.after(delay, &action)
    end

    #
    # See {EventQueue#at_each}.
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
    def at_each elements, time=nil, &action
      event_queue.at_each(elements, time, &action)
    end

    #
    # See {EventQueue#recur_after}.
    #
    # @param [Number] interval non-negative
    #
    # @return [nil]
    #
    def recur_after interval
      event_queue.recur_after(interval)
    end

    # 
    # See {EventQueue#every}.
    #
    # @param [Numeric] interval non-negative
    #
    # @param [Numeric] start block first runs at this time
    #
    # @return [nil]
    def every interval, start=0, &action
      event_queue.every(interval, start, &action)
    end

    #
    # See {EventQueue#now}.
    #
    # @return [Number]
    #
    def now
      event_queue.now
    end
  end
end

