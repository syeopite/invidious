{% skip_file if flag?(:api_only) %}

module Invidious::Routes::Misc
  def self.home(env)
    preferences = env.get("preferences").as(Preferences)
    locale = preferences.locale
    user = env.get? "user"

    case preferences.default_home
    when "Popular"
      env.redirect "/feed/popular"
    when "Trending"
      env.redirect "/feed/trending"
    when "Subscriptions"
      if user
        env.redirect "/feed/subscriptions"
      else
        env.redirect "/feed/popular"
      end
    when "Playlists"
      if user
        env.redirect "/feed/playlists"
      else
        env.redirect "/feed/popular"
      end
    else
      templated "search_homepage", navbar_search: false
    end
  end

  def self.privacy(env)
    locale = env.get("preferences").as(Preferences).locale
    templated "privacy"
  end

  def self.licenses(env)
    locale = env.get("preferences").as(Preferences).locale
    rendered "licenses"
  end

  def self.cross_instance_redirect(env)
    referer = get_referer(env)

    instance_list = Invidious::Jobs::InstanceListRefreshJob::INSTANCES["INSTANCES"]
    # Filter out the current instance
    other_available_instances = instance_list.reject { |_, domain| domain == CONFIG.domain }

    if other_available_instances.empty?
      # If the current instance is the only one, use the redirect URL as fallback
      instance_url = "redirect.invidious.io"
    else
      # Select other random instance
      # Sample returns an array
      # Instances are packaged as {region, domain} in the instance list
      instance_url = other_available_instances.sample(1)[0][1]
    end

    env.redirect "https://#{instance_url}#{referer}"
  end

  def self.track_mem(env)
    Invidious::Jobs::LogMemory.track
    return "Tracked!"
  end

  def self.graph_indirection_to_file(env)
    env.response.headers["content-type"] = "plain/text"
    if env.params.query["xml"]?
      PerfTools::MemProf.pretty_log_object_graph(env.response, XML::Node)
    elsif env.params.query["jsonarrayany"]?
      PerfTools::MemProf.pretty_log_object_graph(env.response, Array(JSON::Any))
    elsif env.params.query["jsonhashstringany"]?
      PerfTools::MemProf.pretty_log_object_graph(env.response, Hash(String, JSON::Any))
    else
      PerfTools::MemProf.pretty_log_object_graph(env.response, TCPSocket)
    end
  end

  def self.collect_mem(env)
    times = env.params.query["times"]?.try &.to_i? || 5
    delay = env.params.query["delay"]?.try &.to_f? || 0.2

    gc_stats = measure_before_after_gc do
      times.times do
        GC.collect
        sleep delay.seconds
      end
    end

    env.response.content_type = "application/json"
    return gc_stats.to_pretty_json
  end

  def self.measure_before_after_gc(&)
    before = self.get_human_readable_gc_data
    yield
    after = self.get_human_readable_gc_data

    return {"before": before, "after": after}
  end

  def self.get_human_readable_gc_data
    {
      heap_size:      GC.stats.heap_size.humanize_bytes,
      free_bytes:     GC.stats.free_bytes.humanize_bytes,
      unmapped_bytes: GC.stats.unmapped_bytes.humanize_bytes,
      bytes_since_gc: GC.stats.bytes_since_gc.humanize_bytes,
      total_bytes:    GC.stats.total_bytes.humanize_bytes,
    }
  end
end
