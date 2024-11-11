# Mapping of subdomain => Invidious::ConnectionPool::Pool
# This is needed as we may need to access arbitrary subdomains of ytimg
private YTIMG_POOLS = {} of String => Invidious::ConnectionPool::Pool

def add_yt_headers(request)
  request.headers.delete("User-Agent") if request.headers["User-Agent"] == "Crystal"
  request.headers["User-Agent"] ||= "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

  request.headers["Accept-Charset"] ||= "ISO-8859-1,utf-8;q=0.7,*;q=0.7"
  request.headers["Accept"] ||= "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
  request.headers["Accept-Language"] ||= "en-us,en;q=0.5"

  # Preserve original cookies and add new YT consent cookie for EU servers
  request.headers["Cookie"] = "#{request.headers["cookie"]?}; CONSENT=PENDING+#{Random.rand(100..999)}"
  if !CONFIG.cookies.empty?
    request.headers["Cookie"] = "#{(CONFIG.cookies.map { |c| "#{c.name}=#{c.value}" }).join("; ")}; #{request.headers["cookie"]?}"
  end
end

def make_client(url : URI, region = nil, force_resolve : Bool = false, force_youtube_headers : Bool = false)
  client = HTTP::Client.new(url)
  client.proxy = make_configured_http_proxy_client() if CONFIG.http_proxy

  # Force the usage of a specific configured IP Family
  if force_resolve
    client.family = CONFIG.force_resolve
    client.family = Socket::Family::INET if client.family == Socket::Family::UNSPEC
  end

  client.before_request { |r| add_yt_headers(r) } if url.host.try &.ends_with?("youtube.com") || force_youtube_headers
  client.read_timeout = 10.seconds
  client.connect_timeout = 10.seconds

  return client
end

def make_client(url : URI, region = nil, force_resolve : Bool = false, &)
  client = make_client(url, region, force_resolve: force_resolve)
  begin
    yield client
  ensure
    client.close
  end
end

def make_configured_http_proxy_client
  # This method is only called when configuration for an HTTP proxy are set
  config_proxy = CONFIG.http_proxy.not_nil!

  return HTTP::Proxy::Client.new(
    config_proxy.host,
    config_proxy.port,

    username: config_proxy.user,
    password: config_proxy.password,
  )
end

# Fetches a HTTP pool for the specified subdomain of ytimg.com
#
# Creates a new one when the specified pool for the subdomain does not exist
def get_ytimg_pool(subdomain)
  if pool = YTIMG_POOLS[subdomain]?
    return pool
  else
    LOGGER.info("ytimg_pool: Creating a new HTTP pool for \"https://#{subdomain}.ytimg.com\"")
    pool = Invidious::ConnectionPool::Pool.new(
      URI.parse("https://#{subdomain}.ytimg.com"),
      max_capacity: CONFIG.pool_size,
      idle_capacity: CONFIG.idle_pool_size
    )
    YTIMG_POOLS[subdomain] = pool

    return pool
  end
end
