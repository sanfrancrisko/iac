#!/usr/bin/env ruby
# frozen_string_literal: true

INTERESTED_FILE = '.github/workflows'
DATE_TIME_CUT_OFF = 1561982400 # 2020-07-01 12:00:00 UTC

raise 'Please set Github API token in ENV VAR $GITHUB_TOKEN' unless ENV['GITHUB_TOKEN']

require_relative 'octokit_utils'
require 'json'

MANAGED_MODULES_URI = 'https://puppetlabs.github.io/iac/modules.json'

uri = URI.parse(MANAGED_MODULES_URI)
response = Net::HTTP.get_response(uri)
output = response.body
repos = JSON.parse(output)

util = OctokitUtils.new(ENV['GITHUB_TOKEN'])
client = util.client

repos.each do |_k, v|
  repo_name = v['title']
  puts "\nQuerying the following PRs in #{repo_name}:"
  page_num = 1
  suspect_prs = []
  pr_res = client.get("repos/puppetlabs/#{repo_name}/pulls", state: 'all', page: page_num)
  pr_max_date = false
  until pr_res.empty? or pr_max_date do
    pr_res.each do |pr|
      pr_number = pr['number']
      if pr[:created_at].to_i < DATE_TIME_CUT_OFF
        puts "\n=== PR ##{pr_number} was created before 2020-07-01 12:00:00 - no more PRs will be processed for #{repo_name} ===\n"
        pr_max_date = true
      end
      break if pr_max_date
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