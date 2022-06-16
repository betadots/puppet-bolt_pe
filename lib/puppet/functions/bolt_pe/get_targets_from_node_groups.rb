require 'net/http'
require 'puppet'
Puppet::Functions.create_function(:'bolt_pe::get_targets_from_node_groups') do
  dispatch :run do
    param 'String', :node_group
  end

  def run(node_group)
    value = {}
    # get a list of all existing node groups
    cert   = `/opt/puppetlabs/bin/puppet config print hostcert`.chomp
    cacert = `/opt/puppetlabs/bin/puppet config print localcacert`.chomp
    key    = `/opt/puppetlabs/bin/puppet config print hostprivkey`.chomp
    server = `/opt/puppetlabs/bin/puppet config print server`.chomp

    all_groups_uri = URI("https://#{server}:4433/classifier-api/v1/groups")

    all_groups_http = Net::HTTP.new(all_groups_uri.host, all_groups_uri.port)
    all_groups_http.use_ssl = true
    all_groups_http.ca_file = cacert
    all_groups_http.cert = OpenSSL::X509::Certificate.new(File.read(cert))
    all_groups_http.key = OpenSSL::PKey::RSA.new(File.read(key))
    all_groups_request = Net::HTTP::Get.new all_groups_uri
    all_groups_response = all_groups_http.request(all_groups_request)

    case all_groups_response.code
    when '200'
      all_groups_result = JSON.parse(all_groups_response.body)
      all_groups_result.each do |element|
        value[element['name']] = element['id']
      end
    else
      raise StandardError, "Response from #{server} was HTTP #{all_groups_response.code} - #{all_groups_response.message}"
    end

    # Get rule from node group
    id = value[node_group]
    get_rule_uri = URI("https://#{server}:4433/classifier-api/v1/groups/#{id}/rules")

    get_rule_http = Net::HTTP.new(get_rule_uri.host, get_rule_uri.port)
    get_rule_http.use_ssl = true
    get_rule_http.ca_file = cacert
    get_rule_http.cert = OpenSSL::X509::Certificate.new(File.read(cert))
    get_rule_http.key = OpenSSL::PKey::RSA.new(File.read(key))
    get_rule_request = Net::HTTP::Get.new get_rule_uri
    get_rule_response = get_rule_http.request(get_rule_request)

    case get_rule_response.code
    when '200'
      get_rule_result = JSON.parse(get_rule_response.body)
    else
      raise StandardError, "Response from #{server} was HTTP #{all_groups_response.code} - #{all_groups_response.message}"
    end

    # Transform API rule into PQL
    translate_uri = URI("https://#{server}:4433/classifier-api/v1/rules/translate?format=inventory")
    translate_data = get_rule_result['rule_with_inherited'].to_json

    translate_http = Net::HTTP.new(translate_uri.host, translate_uri.port)
    translate_http.use_ssl = true
    translate_http.ca_file = cacert
    translate_http.cert = OpenSSL::X509::Certificate.new(File.read(cert))
    translate_http.key = OpenSSL::PKey::RSA.new(File.read(key))
    translate_request = Net::HTTP::Post.new(translate_uri.request_uri)
    translate_request.body = translate_data
    translate_request['Content-Type'] = 'application/json'
    translate_response = translate_http.request(translate_request)

    case translate_response.code
    when '200'
      translate_result = JSON.parse(translate_response.body)['query']
    else
      raise StandardError, "Response from #{server} was HTTP #{all_groups_response.code} - #{all_groups_response.message}"
    end

    # Query PuppetDB for nodes
    result = []
    puppetdb_result = call_function('puppetdb_query', ['from', 'nodes', translate_result])
    puppetdb_result.each do |element|
      result << element['certname']
    end

    result
  end
end
