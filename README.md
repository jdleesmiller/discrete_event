# discrete_event

http://github.com/jdleesmiller/discrete_event

![CI status](https://github.com/jdleesmiller/discrete_event/actions/workflows/ruby.yml/badge.svg)

## SYNOPSIS

This gem provides some tools for discrete event simulation (DES) in ruby. The
main one is a DiscreteEvent::EventQueue that stores actions (ruby blocks) to
be executed at chosen times.

The example below uses the DiscreteEvent::Simulation class, which is a
subclass of DiscreteEvent::EventQueue, to simulate an M/M/1 queueing system.

```rb
require 'discrete_event'

#
# A single-server queueing system with Markovian arrival and service
# processes.
#
# Note that the simulation runs indefinitely, and that it doesn't collect
# statistics; this is left to the user. See mm1_queue_demo, below, for
# an example of how to collect statistics and how to stop the simulation
# by throwing the :stop symbol.
#
class MM1Queue < DiscreteEvent::Simulation
  Customer = Struct.new(:arrival_time, :queue_on_arrival,
                        :service_begin, :service_end)

  attr_reader :arrival_rate, :service_rate, :system, :served

  def initialize(arrival_rate, service_rate)
    super()
    @arrival_rate = arrival_rate
    @service_rate = service_rate
    @system = []
    @served = []
  end

  # Sample from Exponential distribution with given mean rate.
  def rand_exp(rate)
    -Math.log(rand) / rate
  end

  # Customer arrival process.
  # The after method is provided by {DiscreteEvent::Simulation}.
  # The given action (a Ruby block) will run after the random delay
  # computed by rand_exp. When it runs, the last thing the action does is
  # call new_customer, which creates an event for the next customer.
  def new_customer
    after rand_exp(arrival_rate) do
      system << Customer.new(now, queue_length)
      serve_customer if system.size == 1
      new_customer
    end
  end

  # Customer service process.
  def serve_customer
    system.first.service_begin = now
    after rand_exp(service_rate) do
      system.first.service_end = now
      served << system.shift
      serve_customer unless system.empty?
    end
  end

  # Number of customers currently waiting for service (does not include
  # the one (if any) currently being served).
  def queue_length
    if system.empty?
      0
    else
      system.length - 1
    end
  end

  # Called by super.run.
  def start
    new_customer
  end
end

#
# Run until a fixed number of passengers has been served.
#
def mm1_queue_demo(arrival_rate, service_rate, num_pax)
  # Run simulation and accumulate stats.
  q = MM1Queue.new arrival_rate, service_rate
  num_served = 0
  total_queue = 0.0
  total_wait = 0.0
  q.run do
    unless q.served.empty?
      raise 'confused' if q.served.size > 1
      c = q.served.shift
      total_queue += c.queue_on_arrival
      total_wait  += c.service_begin - c.arrival_time
      num_served  += 1
    end
    throw :stop if num_served >= num_pax
  end

  # Use standard formulas for comparison.
  rho = arrival_rate / service_rate
  expected_mean_wait = rho / (service_rate - arrival_rate)
  expected_mean_queue = arrival_rate * expected_mean_wait

  [
    total_queue / num_served, expected_mean_queue,
    total_wait  / num_served, expected_mean_wait
  ]
end
```

This and other examples are available in the `test/discrete_event` directory.

In this example, the whole simulation happens in a single object; if you have
multiple objects, you can use the DiscreteEvent::Events mix-in to make them
easily share a single event queue.

## INSTALLATION

```
gem install discrete_event
```

## REFERENCES

- http://en.wikipedia.org/wiki/Discrete_event_simulation

You may also be interested in the Ruby bindings of the GNU Science Library,
which provides a variety of pseudo-random number generators and functions for
generating random variates from various distributions. It also provides useful
things like histograms.

- http://www.gnu.org/software/gsl/
- https://rubygems.org/gems/rb-gsl
- The libgsl-ruby package in Debian.


## HISTORY

### 3.0.0
- drop support for rubies older than 2.6
- change priority queue implementation to `priority_queue_cxx` (https://rubygems.org/gems/priority_queue_cxx) for performance

### 2.0.0
- drop support for rubies older than 2.2
- allow installation with PQueue 2.1
- updated dev dependencies
- code has been linted with rubocop

### 1.1.0
- compatibility with PQueue 2.x; fix for event cancellation (thanks: joshcarter)
- added DiscreteEvent::EventQueue#run_to
- updated dependency versions

### 1.0.0:
- split DiscreteEvent::EventQueue out of DiscreteEvent::Simulation for easier sharing between objects
- added DiscreteEvent::Events mix-in

### 0.3.0
- reorganized for compatibility with gemma 2.0; no functional changes
- added major, minor and patch version constants

### 0.2.0
-  added DiscreteEvent::Simulation#at_each_index (removed in 1.0.0)
-  added DiscreteEvent::Simulation#recur_after
-  added DiscreteEvent::Simulation#every
-  DiscreteEvent::FakeRand now supports the `Kernel::rand(n)` form.

### 0.1.0
- first release


## LICENSE

Copyright (c) 2010–2021 John Lees-Miller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
