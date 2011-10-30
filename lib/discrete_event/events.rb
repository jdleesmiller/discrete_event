module DiscreteEvent
  #
  # Mix-in for simulations with multiple objects that have to share the same
  # clock. See the {file:README} for an example.
  #
  # The implementing class must have an instance variable <tt>@event_queue</tt>
  # that references the {EventQueue} to use.
  #
  module Events
    def at time, &action
      @event_queue.at(time, &action)
    end

    def after delay, &action
      @event_queue.after(delay, &action)
    end

    def at_each elements, time=nil, &action
      @event_queue.at_each(elements, time, &action)
    end

    def recur_after interval
      @event_queue.recur_after(interval)
    end

    def every interval, start=0, &action
      @event_queue.every(interval, start, &action)
    end
  end
end
