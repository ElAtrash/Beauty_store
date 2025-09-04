module RequestHelpers
  def modern_browser_headers
    {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
