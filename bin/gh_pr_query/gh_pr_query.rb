#!/usr/bin/env ruby
# frozen_string_literal: true

raise 'Please set Github API token in ENV VAR $GITHUB_TOKEN' unless ENV['GITHUB_TOKEN']

require_relative 'octokit_utils'
require 'json'

INTERESTED_FILE = '.github/workflows'
MANAGED_MODULES_URI = 'https://puppetlabs.github.io/iac/modules.json'
uri = URI.parse(MANAGED_MODULES_URI)
response = Net::HTTP.get_response(uri)
output = response.body
repos = JSON.parse(output)

util = OctokitUtils.new(ENV['GITHUB_TOKEN'])
client = util.client

repos.each do |_k, v|
  repo_name = v['title']
  next unless repo_name =~ %r{motd}
  puts "Querying the following PRs in #{repo_name}:"
  page_num = 1
  suspect_prs = []
  pr_res = client.get("repos/puppetlabs/#{repo_name}/pulls", state: 'all', page: page_num)
  until pr_res.empty? do
    pr_res.each do |pr|
      pr_number = pr['number']
      puts "##{pr_number}: "
      files_changed = client.get("/repos/puppetlabs/#{repo_name}/pulls/#{pr_number}/files")
      files_changed.each do |file|
        filename = file['filename']
        puts "- #{filename}"
        next unless filename.include? INTERESTED_FILE
        suspect_prs << pr['html_url']
      end
    end
    page_num += 1
    pr_res = client.get("repos/puppetlabs/#{repo_name}/pulls", state: 'all', page: page_num)
  end
  next if suspect_prs.empty?
  filename = "#{repo_name}_#{DateTime.now.strftime('%F_%T')}".gsub(/[-,:]/, '_')
  puts "Writing results to #{filename} (#{suspect_prs.size} PRs to be inspected)"
  File.open(filename, 'w') do |file|
    suspect_prs.each do |pr|
      file.puts pr
    end
  end
end