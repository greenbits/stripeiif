#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'stripeiif/entry'
require 'stripeiif/parser'
require 'stripeiif/statement'
require 'csv'

def prompt_for_iif_filename
  #"/Users/bcurren/Downloads/balance_history_stripe.iif"
  printf "What's the full path to the iif file to convert? "
  filename = gets.strip
  if !File.exist?(filename)
    puts "Unable to open file: '#{filename}'. Please check and try again."
    nil
  else
    filename
  end
end

def calc_csv_filename(iif_filename)
  iif_filename + ".csv"
end

# Get the stripe iif file location
iif_filename = prompt_for_iif_filename
if iif_filename == nil
  exit 1
end

stripe_iif = begin
  File.read(iif_filename)
rescue
  puts "Error while reading '#{iif_filename}'."
  exit 2
end

# Parse stripe iif file
parser = StripeIif::Parser.new(stripe_iif)
puts "Reading and processing the stripe iif file ..."
entries = parser.parse

# Create statement and merge fees daily
statement = StripeIif::Statement.new(entries)
statement.merge_fees!

# Write to csv file
csv_filename = calc_csv_filename(iif_filename)
puts "Saving csv file to '#{csv_filename}'."
CSV.open(csv_filename, "wb") do |csv|
  csv << ['*Date', '*Amount', 'Payee', 'Description', 'Reference']

  statement.to_a.each do |statement_line|
    csv << statement_line
  end
end
