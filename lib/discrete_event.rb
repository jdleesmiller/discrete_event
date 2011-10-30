require 'pqueue'

require 'discrete_event/event_queue'
require 'discrete_event/events'
require 'discrete_event/simulation'
require 'discrete_event/fake_rand'

module DiscreteEvent
  def self.simulation *args, &block 
    sim = DiscreteEvent::Simulation.new(*args)
    sim.instance_eval(&block)
    sim
  end
end
