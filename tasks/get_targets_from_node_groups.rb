#!/usr/bin/env ruby
# frozen_string_literal: true
require 'net/http'
require 'puppet'

# Initialize Puppet so that the task can make use of
# the Puppet::Network::HttpPool for communication.
def initialize_puppet
  Puppet.initialize_settings(['--libdir=/dev/null', '--factpath=/dev/null'])
end

def run(node_group)
  # get a list of all existing node groups
  cert   = `/opt/puppetlabs/bin/puppet config print hostcert`.strip
  cacert = `/opt/puppetlabs/bin/puppet config print localcacert`.strip
  key    = `/opt/puppetlabs/bin/puppet config print hostprivkey`.strip
  server = `/opt/puppetlabs/bin/puppet config print server`.strip

  crt_obj = OpenSSL::X509::Certificate.new(File.read(cert))
  key_obj = OpenSSL::PKey::RSA.new(File.read(key))

  all_groups_uri = URI("https://#{server}:4433/classifier-api/v1/groups")

  all_groups_http = Net::HTTP.new(all_groups_uri.host, all_groups_uri.port)
  all_groups_http.use_ssl = true
  all_groups_http.ca_file = cacert
  all_groups_http.cert = crt_obj
  all_groups_http.key = key_obj
  all_groups_request = Net::HTTP::Get.new all_groups_uri
  all_groups_response = all_groups_http.request(all_groups_request)

  raise StandardError, "ERROR #{all_groups_response.code} - #{all_groups_response.message}" unless all_groups_response.code == '200'
  all_groups_result = JSON.parse(all_groups_response.body)
  ids = all_groups_result.map { |e| [e['name'], e['id']] }.to_h

  # Get rule from node group
  get_rule_uri = URI("https://#{server}:4433/classifier-api/v1/groups/#{ids[node_group]}/rules")

  get_rule_http = Net::HTTP.new(get_rule_uri.host, get_rule_uri.port)
  get_rule_http.use_ssl = true
  get_rule_http.ca_file = cacert
  get_rule_http.cert = crt_obj
  get_rule_http.key = key_obj
  get_rule_request = Net::HTTP::Get.new get_rule_uri
  get_rule_response = get_rule_http.request(get_rule_request)

  raise StandardError, "ERROR #{all_groups_response.code} - #{all_groups_response.message}" unless get_rule_response.code == '200'
  get_rule_result = JSON.parse(get_rule_response.body)

  # Transform API rule into PQL
  translate_uri = URI("https://#{server}:4433/classifier-api/v1/rules/translate?format=inventory")
  translate_data = get_rule_result['rule_with_inherited'].to_json

  translate_http = Net::HTTP.new(translate_uri.host, translate_uri.port)
  translate_http.use_ssl = true
  translate_http.ca_file = cacert
  translate_http.cert = crt_obj
  translate_http.key = key_obj
  translate_request = Net::HTTP::Post.new(translate_uri.request_uri)
  translate_request.body = translate_data
  translate_request['Content-Type'] = 'application/json'
  translate_response = translate_http.request(translate_request)

  raise StandardError, "ERROR #{all_groups_response.code} - #{all_groups_response.message}" unless translate_response.code == '200'
  translate_result = JSON.parse(translate_response.body)['query']

  # Query PuppetDB for nodes
  puppetdb_uri = URI("https://#{server}:8081/pdb/query/v4")
  puppetdb_uri.query = URI.encode_www_form({ query: "[\"from\", \"nodes\", #{translate_result}]" })

  puppetdb_http = Net::HTTP.new(puppetdb_uri.host, puppetdb_uri.port)
  puppetdb_http.use_ssl = true
  puppetdb_http.ca_file = cacert
  puppetdb_http.cert = crt_obj
  puppetdb_http.key = key_obj
  puppetdb_request = Net::HTTP::Get.new(puppetdb_uri)
  puppetdb_response = puppetdb_http.request(puppetdb_request)

  raise StandardError, "ERROR #{puppetdb_response.code} - #{puppetdb_response.message}" unless puppetdb_response.code == '200'
  puppetdb_result = JSON.parse(puppetdb_response.body)

  # return array of certnames
  puppetdb_result.map { |element| element['certname'] }
end

params = JSON.parse(STDIN.read)
node_group = params['node_group']

begin
  result = run(node_group)
  puts result.to_json
  exit 0
rescue Puppet::Error => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end

