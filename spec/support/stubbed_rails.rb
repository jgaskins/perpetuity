module Rails
  def self.application
    @application ||= Application.new
  end

  class Application
    def config
      @config ||= Configuration.new
    end
  end

  class Configuration
    def middleware
      @middleware ||= MiddlewareStack.new
    end
  end

  class MiddlewareStack
    include Enumerable

    def initialize
      @stack = []
    end

    def use klass
      @stack << klass
    end

    def each &block
      @stack.each &block
    end
  end
end
