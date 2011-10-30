require 'discrete_event/test_helper'

require 'discrete_event/ex_consumer.rb'
require 'discrete_event/ex_mm1_queue.rb'

include DiscreteEvent
include DiscreteEvent::Example

class TestDiscreteEvent < Test::Unit::TestCase
  def assert_near expected, observed, tol=1e-6
    assert((expected - observed).abs < tol,
      "expected |#{expected} - #{observed}| < #{tol}")
  end

  def test_fake_rand
    c = ConsumerSim.new 3

    # Before faking.
    c.run
    assert_equal 3, c.consumed.size

    # Fake rand.
    FakeRand.for(c, 0.125, 0.25, 0.5)
    c.reset.run
    assert_equal [0.125, 0.375, 0.875], c.consumed

    # Now have run out of fakes.
    assert_raise(RuntimeError){ c.reset.run }

    # See what happens if we fake twice.
    FakeRand.for(c, 0.5, 0.25, 0.125)
    c.reset.run
    assert_equal [0.5, 0.75, 0.875], c.consumed

    # Now have run out of fakes, again.
    assert_raise(RuntimeError){ c.reset.run }

    # Can undo and get original behavior back.
    FakeRand.undo_for(c)
    c.reset.run # no exception
    assert_equal 3, c.consumed.size
  end

  def test_fake_rand_n
    # Test that we can also fake random integers (for Kernel::rand(n)).
    o = Object.new
    class <<o
      def test
        rand(11)
      end
    end

    FakeRand.for(o, 0.0, 0.1, 0.5, 0.99)
    assert_equal 0, o.test
    assert_equal 1, o.test
    assert_equal 5, o.test
    assert_equal 10, o.test

    # Now have run out of fakes.
    assert_raise(RuntimeError){ o.test }
  end
  
  def test_mm1_queue_not_busy
    # Service begins immediately when queue is not busy.
    q = MM1Queue.new 0.5, 1.0
    fakes = [1, 1, 1, 1, 1].map {|x| 1/Math::E**x}
    FakeRand.for(q, *fakes)
    q.run do
      throw :stop if q.served.size >= 2
    end
    assert_near 2.0, q.served[0].arrival_time
    assert_near 2.0, q.served[0].service_begin
    assert_near 3.0, q.served[0].service_end
    assert_near 4.0, q.served[1].arrival_time
    assert_near 4.0, q.served[1].service_begin
    assert_near 5.0, q.served[1].service_end
  end
  
  def test_mm1_queue_busy
    # Service begins after previous customer when queue is busy.
    q = MM1Queue.new 0.5, 1.0
    fakes = [0.1, 0.1, # arrival, service for first customer
      0.01, 0.01,      # arrival times for second two customers
      1,               # arrival for forth customer
      0.1, 0.1,        # service times for second two customers
      1].map {|x| 1/Math::E**x}
    FakeRand.for(q, *fakes)
    q.run do
      throw :stop if q.served.size >= 3
    end
    assert_near 0.2,  q.served[0].arrival_time
    assert_near 0.2,  q.served[0].service_begin
    assert_near 0.3,  q.served[0].service_end
    assert_near 0.22, q.served[1].arrival_time
    assert_near 0.3,  q.served[1].service_begin
    assert_near 0.4,  q.served[1].service_end
    assert_near 0.24, q.served[2].arrival_time
    assert_near 0.4,  q.served[2].service_begin
    assert_near 0.5,  q.served[2].service_end
  end

  def test_recur_after
    output = []
    DiscreteEvent.simulation {
      at 0 do
        output << now
        recur_after 5 if now < 20
      end

      run
    }
    assert_equal [0, 5, 10, 15, 20], output
  end

  def test_recur_after_with_after_0
    # Putting a new event in the queue and then calling recur_after should not
    # displace the root element, even if you call after(0), which is just an
    # edge case anyway.
    output = []
    DiscreteEvent.simulation {
      at 0 do
        output << now
        after 0 do
          output << 42
        end
        after 1 do
          output << 13
        end
        recur_after 5 if now < 10
      end

      run
    }
    assert_equal [0, 42, 13, 5, 42, 13, 10, 42, 13], output
  end

  def test_every
    output = []
    DiscreteEvent.simulation {
      every 3 do
        output << now
        throw :stop if now > 10
      end
      run
    }
    assert_equal [0,3,6,9,12], output
  end

  Alert = Struct.new(:when, :message)

  def test_at_each_with_symbol
    output = []
    DiscreteEvent.simulation {
      alerts = [Alert.new(12, "ha!"), Alert.new(42, "ah!")] # and many more
      at_each alerts, :when do |alert|
        output << now << alert.message
      end
      run
    }
    assert_equal [12, 'ha!', 42, 'ah!'], output
  end

  def test_at_each_with_proc
    output = []
    DiscreteEvent.simulation {
      alerts = [Alert.new(12, "ha!"), Alert.new(42, "ah!")] # and many more
      at_each(alerts, proc{|alert| alert.when}) do |alert|
        output << now << alert.message
      end
      run
    }
    assert_equal [12, 'ha!', 42, 'ah!'], output
  end

  Alert2 = Struct.new(:time, :message)
  def test_at_each_with_default
    output = []
    DiscreteEvent.simulation {
      alerts = [Alert2.new(12, "ha!"), Alert2.new(42, "ah!")] # and many more
      at_each alerts do |alert|
        output << now << alert.message
      end
      run
    }
    assert_equal [12, 'ha!', 42, 'ah!'], output
  end

  def test_next_event_time
    output= []
    s = DiscreteEvent.simulation {
      at 0 do
        output << next_event_time
      end

      at 5 do
        output << next_event_time
      end
    }
    assert_equal 0, s.next_event_time
    assert s.run_next
    assert_equal 5, s.next_event_time
    assert s.run_next
    assert_nil s.next_event_time

    # as currently implemented, the "next" event includes the current event
    assert_equal [0, 5], output
  end

  def test_enumerator
    output = []
    output_times = []
    eq = EventQueue.new
    eq.at 13 do
      output << 'hi'
    end
    eq.at 42 do
      output << 'bye'
    end
    for t in eq.to_enum
      output_times << t
    end
    assert_equal %w(hi bye), output
    assert_equal [13, 42], output_times
  end
  
  def test_mm1_queue_demo
    # Just run the demo... 1000 isn't enough to get a reliable average.
    obs_q, exp_q, obs_w, exp_w= mm1_queue_demo(0.25, 0.5, 1000)
    assert_near exp_q, 0.5   # mean queue = rho^2 / (1 - rho)
    assert_near exp_w, 2.0   # mean wait  = rho / (mu - lambda)
  end

  def test_producer_consumer
    event_queue = EventQueue.new(0)
    consumer = Consumer.new(event_queue)
    producer = Producer.new(event_queue, %w(a b c d), consumer)

    FakeRand.for(consumer, 2, 2, 2, 2)
    FakeRand.for(producer, 1, 1, 1, 1)

    producer.produce
    output = []
    event_queue.each do |now|
      output << [now, consumer.consumed.dup]
    end
    assert_equal [
      [1, []],                # first object produced
      [2, []],                # second object produced
      [3, ["a"]],             # third object produced / first consumed
      [3, ["a"]],
      [4, ["a", "b"]],        # fourth object produced / second consumed
      [4, ["a", "b"]],
      [5, ["a", "b", "c"]],   # third and fourth objects consumed
      [6, ["a", "b", "c", "d"]]], output
  end
end

