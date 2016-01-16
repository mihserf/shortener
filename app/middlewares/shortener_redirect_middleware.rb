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
      [301, {'Location' => shortener.url}, []]
    else
      location = ::Shortener.main_url.present? ? ::Shortener.main_url : '/'
      redirect_to_root ? [301, {'Location' => location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []] : @app.call(env)
    end
  end
end
