# Created by Andrew Bell 08/24/2015
# www.recursivechaos.com
# andrew@recursivechaos.com
# Licensed under MIT License 2016. See license.txt for details.



require 'csv'
require 'logger'
require 'optparse'
require 'bundler/setup'
Bundler.require(:default)

log = Logger.new(STDOUT)
log.level = Logger::INFO

# Configures command line arguments
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: zendesk.rb [options]"

  # Enables debug with -verbose
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
    log.level = Logger::DEBUG
  end

  # Pass queries in as comma delimited array
  opts.on("-qqueries", "--queries=NAME", "Accepts list of queries as a comma delimited string") do |v|
    options[:queries] = v
  end

  # Supply username
  opts.on("-uUSERNAME", "--username=UNAME", "Zendesk account username") do |v|
    options[:username] = v
  end

  # Supply password
  opts.on("-pPASSWORD", "--password=PASSWORD", "Zendesk password") do |v|
    options[:password] = v
  end
end.parse!

p options

if !options[:queries]
  log.fatal("You probably should give me some queries to look for with the -q flag. See --help for details")
  exit(1)
end

if !options[:username] || !options[:password]
  log.fatal("You gotta give me some credentials dude. use the -u and -p flag. See --help for details")
  exit(1)
end

log.info("Generating report for: " + options[:queries])

# Configures client
client = ZendeskAPI::Client.new do |config|
  config.url = "https://promisepay.zendesk.com/api/v2"
  config.logger = log
  config.username = options[:username]
  config.password = options[:password]
end

# Iterates through list of queries
open_tickets = []
queries = options[:queries].split(', ')
queries.each do |query|

  # Queries tickets for queries
  tickets = client.search(query: query)
  tickets.each do |ticket|
    if ticket.status != "closed" && ticket.status != "solved" && ticket.subject != nil
      ticket.query = query
      open_tickets << ticket
    end
  end
end

# Write to file
timestamp = Time.now.strftime("%Y-%m-%d-%H-%M")
CSV.open("export/report_#{timestamp}.csv", "wb") do |csv|
  csv << ["Company", "Priority", "Subject", "Status", "Assignee", "Zendesk Id", "Updated"]
  open_tickets.each do |ticket|
    csv << [ticket.query, ticket.priority, ticket.subject, ticket.status, ticket.assignee_id, ticket.id, ticket.updated_at ]
    log.debug "Company: #{ticket.query} | Priority: #{ticket.priority} | Subject: #{ticket.subject} | Status: #{ticket.status} | Assignee: #{ticket.assignee_id} | ZenDesk: #{ticket.id} | Updated: #{ticket.updated_at} "
  end
end