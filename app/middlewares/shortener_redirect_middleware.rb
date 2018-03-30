class ShortenerRedirectMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if ::Shortener.short_host_name.present?
      handle_short_url_within_host(env)
    else
      handle_short_url(env)
    end
  end


  private

  def handle_short_url_within_host(env)
    request = Rack::Request.new(env)
    host = request.host.downcase # downcase for case-insensitive matching
    if host == ::Shortener.short_host_name
      handle_short_url(env, true)
    else
      @app.call(env)
    end
  end

  def handle_short_url(env, redirect_to_root=false)
    if (env["PATH_INFO"] =~ ::Shortener.match_url) && (shortener = ::Shortener::ShortenedUrl.find_by_unique_key($1))
      shortener.track env if ::Shortener.tracking
      [301, {'Location' => location_with_merged_params(env, shortener.url)}, []]
    else
      location = ::Shortener.main_url.present? ? ::Shortener.main_url : '/'
      redirect_to_root ? [301, {'Location' => location_with_merged_params(env, location), 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []] : @app.call(env)
    end
  end

  def location_with_merged_params(env, location)
    uri = URI::parse(env['REQUEST_URI'])
    return location if uri.query.blank?

    params = Rack::Utils.parse_nested_query(uri.query)
    uri2 = URI::parse(location)
    params2 = Rack::Utils.parse_nested_query(uri2.query)
    params2.merge!(params)
    query = Rack::Utils.build_query(params2)
    location_without_params = location.split('?')[0]
    [location_without_params, query].join('?')
  end

end
