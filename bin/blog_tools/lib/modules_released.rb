# frozen_string_literal: true

require 'date'
require 'json'
require 'net/http'
require_relative 'common'

FORGE_URI = URI.parse('https://forgeapi.puppetlabs.com/v3/modules?module_groups=base+pe_only&owner=puppetlabs&limit=100')

http = Net::HTTP.new(FORGE_URI.host, FORGE_URI.port)
http.use_ssl = true

request = http.get(FORGE_URI.request_uri)

resp = JSON.parse(request.body)
forge_modules = resp['results']
                .select { |forge_module| iac_repos.include? ("puppetlabs/" + forge_module['slug']) }
                # .select { |forge_module| Date.parse(forge_module['updated_at']).strftime('%s').to_i >= last_blog_post_utc_time }


@module_releases = []

puppet_7_modules = []
modules_still_needing_pushed = []
forge_modules.each do |forge_module|
  module_puppet_requirements = forge_module['current_release']['metadata']['requirements']
                                   .select { |requirement| requirement['name'] == 'puppet' }
                                   .first
  puppet_7_modules << forge_module['slug'] if module_puppet_requirements['version_requirement'].include? '< 8.0.0'
  modules_still_needing_pushed << forge_module['slug'] if module_puppet_requirements['version_requirement'].include? '< 7.0.0'
end

puts "=========================================="
puts "== PUPPET 7 COMPATIBLE MODULES ON FORGE =="
puts "=========================================="
puppet_7_modules.sort.each { |puppet_module| puts " - #{puppet_module}"}
puts "============================================"
puts "== MODULES STILL NEEDING PUSHED TO FORGE =="
modules_still_needing_pushed.sort.each { |puppet_module| puts " - #{puppet_module}"}
puts "============================================"
exit(0)
