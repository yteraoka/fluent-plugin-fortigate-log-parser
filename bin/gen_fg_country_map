#!/usr/bin/env ruby
# coding: utf-8
#
# Usage:
#
# curl -O http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip
# unzip GeoIPCountryCSV.zip
# ruby mkCountryMap.rb GeoIPCountryWhois.csv > country.map
#
require 'csv'

reader = CSV.open(ARGV[0], 'r')
reader.each do |row|
  puts row[5] + "\t" + row[4]
end
