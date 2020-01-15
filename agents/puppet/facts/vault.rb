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

def post_url_json(url, json)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = json
  response = http.request(request)
  JSON.parse(response.body)
end

def vault_response(key, token)
  uri = URI.parse("http://vault.srnd.cloud:8200/v1/kv/data/#{key}")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request['X-Vault-Token'] = token
  response = http.request(request)
  JSON.parse(response.body)['data']['data']
end

def vault_login()
  metadata = get_url_json('http://169.254.169.254/metadata/instance?api-version=2019-08-15')
  subscription_id = metadata['compute']['subscriptionId']
  vm_name = metadata['compute']['name']
  resource_group_name = metadata['compute']['resourceGroupName']

  oauth = get_url_json('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=http%3A%2F%2Fvault.srnd.cloud')
  jwt = oauth['access_token']

  login_request = JSON.generate({
    role: 'nomad-server',
    jwt: jwt,
    subscription_id: subscription_id,
    resource_group_name: resource_group_name,
    vm_name: vm_name,
  })

  vault_login = post_url_json("http://vault.srnd.cloud:8200/v1/auth/azure/login", login_request)
  vault_login['auth']['client_token']
end

Facter.add('vault_token') do
  setcode do
    vault_login()
  end
end

Facter.add('vault') do
  setcode do
    vault_response('nomad-agent', Facter.value(:vault_token))
  end
end

Facter.add('vault_ssh_users') do
  setcode do
    vault_response('ssh-users', Facter.value(:vault_token))
  end
end
