#!/usr/bin/env ruby 

require 'digest/sha1'
require './flickr_init' 
require 'digest/sha1'
require 'yaml'

@debug = 1
#####
# Base upload directory
base_dir = "/stuff/Pictures/2012"


#####
# username whose photos we're messing with re '
username = "skippy39us"


####
# Suck in the yaml of checksums, if it exists
@checksum_hash = {}
if File.exists?("/home/seidenbt/flickr_yaml")
	@checksum_hash = YAML.load_file("/home/seidenbt/flickr_yaml")	
	if @debug.eql? 1 then puts "DEBUG: Found /home/seidenbt/flickr_yaml" end  
	if @debug.eql? 1 then puts "DEBUG: here: #{@checksum_hash.inspect}" end 
end 
		


info = get_user_info(username) 
#get_photo_sets(debug) 
puts
puts "#####"

process_directory("/home/seidenbt/test")

####
# This is every photo that we have. 
#all_photos = get_all_photos(info["id"])

puts @checksum_hash.inspect
YAML::ENGINE.yamler='syck'
checksum_hash_yaml = YAML.dump(@checksum_hash)
yamlfile = File.open("/home/seidenbt/flickr_yaml", 'w')
yamlfile.puts checksum_hash_yaml
yamlfile.close



