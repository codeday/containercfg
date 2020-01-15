require "net/http"
require "json"
require "facter"

def get_url_json(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Metadata'] = 'true'
  response = http.request(request)
  JSON.parse(response.body)
end

Facter.add('role') do
  setcode do
    metadata = get_url_json('http://169.254.169.254/metadata/instance?api-version=2019-08-15')
    tags = metadata['compute']['tagsList'].select do |elem|
      elem['name'] == "role"
    end

    result = nil
    if tags.length > 0
      result = tags[0]['value']
    end
    result
  end
end
