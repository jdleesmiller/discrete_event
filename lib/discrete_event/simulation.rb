module DiscreteEvent
  #
  # A simulation, including an {EventQueue}, the current time, and various
  # helpers.
  #
  # See the {file:README} for an example.
  #
  class Simulation < EventQueue
    #
    # Called by +run+ when beginning a new simulation; you will probably want
    # to override this.
    #
    # @abstract
    #
    def start
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
        if block_given?
          yield while run_next
        else
          nil while run_next
        end
      end
    end
  end
end

