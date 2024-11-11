module Invidious::ConnectionPool
  struct Pool
    property! url : URI
    property! max_capacity : Int32
    property! idle_capacity : Int32
    property! timeout : Float64
    property pool : DB::Pool(HTTP::Client)

    def initialize(
      url : URI,
      *,
      @max_capacity : Int32 = 5,
      idle_capacity : Int32? = nil,
      @timeout : Float64 = 5.0
    )
      if idle_capacity.nil?
        @idle_capacity = @max_capacity
      else
        @idle_capacity = idle_capacity
      end

      @url = url

      @pool = build_pool()
    end

    # Checks out a client in the pool
    def client(&)
      pool.checkout do |http_client|
        # Proxy needs to be reinstated every time we get a client from the pool
        http_client.proxy = make_configured_http_proxy_client() if CONFIG.http_proxy

        response = yield http_client

        return response
      rescue ex : DB::Error
        # Prevent broken client from being checked back into the pool
        http_client.close
        raise ConnectionPool::Error.new(ex.message, cause: ex)
      ensure
        pool.release(http_client)
      end
    rescue ex : DB::PoolTimeout
      # Failed to checkout a client
      raise ConnectionPool::Error.new(ex.message, cause: ex)
    end

    private def build_pool
      # We call the getter for the instance variables instead of using them directly
      # because the getters defined by property! ensures that the value is not a nil
      options = DB::Pool::Options.new(
        initial_pool_size: 0,
        max_pool_size: max_capacity,
        max_idle_pool_size: idle_capacity,
        checkout_timeout: timeout
      )

      DB::Pool(HTTP::Client).new(options) do
        next make_client(url, force_resolve: true)
      end
    end
  end

  class Error < Exception
  end
end