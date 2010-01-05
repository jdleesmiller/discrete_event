require 'helper'

require 'test/ex_consumer.rb'
require 'test/ex_mm1_queue.rb'

include DiscreteEvent
include DiscreteEvent::Example

class TestDiscreteEvent < Test::Unit::TestCase
  def assert_near expected, observed, tol=1e-6
    assert (expected - observed).abs < tol,
      "expected |#{expected} - #{observed}| < #{tol}"
  end

  def test_fake_rand
    c = Consumer.new 3

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
  
  def test_mm1_queue_demo
    # Just run the demo... 10000 isn't enough to get a reliable average.
    obs_q, exp_q, obs_w, exp_w= mm1_queue_demo(0.25, 0.5, 10000)
    assert_near exp_q, 0.5   # mean queue = rho^2 / (1 - rho)
    assert_near exp_w, 2.0   # mean wait  = rho / (mu - lambda)
  end
end
