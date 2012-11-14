module DiscreteEvent
  #
  # A utility for testing objects that use the built-in Ruby pseudorandom
  # number generator (+Kernel::rand+); use it to specify a particular sequence
  # of (non-random) numbers to be returned by +rand+.
  #
  # Using this utility may be better than running tests with a fixed seed,
  # because you can specify random numbers that produce particular behavior.
  #
  # The sequence is specific to the object that you give to {.for}; this means
  # that you must specify a separate fake sequence for each object in the
  # simulation (which is usually easier than trying to specify one sequence for
  # the whole sim, anyway).
  #
  # @example
  #   class Foo
  #     def do_stuff
  #       # NB: FakeRand.for won't work if you write "Kernel::rand" instead of
  #       # just "rand" here.
  #       puts rand
  #     end
  #   end
  #   foo = Foo.new
  #   foo.do_stuff # outputs a pseudorandom number
  #   DiscreteEvent::FakeRand.for(foo, 0.0, 0.1)
  #   foo.do_stuff # outputs 0.0
  #   foo.do_stuff # outputs 0.1
  #   foo.do_stuff # raises an exception
  #
  module FakeRand
    #
    # Create a method +rand+ in +object+'s singleton class that returns the
    # given fake "random numbers;" it raises an error if it runs out of fakes.
    #
    # @param [Object] object to modify
    # @param [Array] fakes sequence of numbers to return
    # @return [nil]
    #
    def self.for object, *fakes
      undo_for(object) # in case rand is already faked
      (class << object; self; end).instance_eval do
        define_method :rand do |*args|
          raise "out of fake_rand numbers" if fakes.empty?
          r = fakes.shift

          # can be either the rand() or rand(n) form
          n = args.shift || 0
          if n == 0
            r
          else
            (r * n).to_i
          end
        end
      end
    end

    #
    # Reverse the effects of {.for}.
    # If object has its own +rand+, it is restored; otherwise, the object
    # goes back to using +Kernel::rand+.
    #
    # @param [Object] object to modify
    # @return [nil]
    #
    def self.undo_for object
      if object.methods.map(&:to_s).member?('rand')
        (class << object; self; end).instance_eval do
          remove_method :rand
        end
      end
    end
  end
end
