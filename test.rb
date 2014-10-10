#!/usr/bin/ruby
require 'find'


pic_hash = {} 

current_dir = "DUMMYDUMMY"
Find.find("/stuff/Pictures/2012/") do |file|
	if FileTest.directory?(file)
		puts "DIRECTORY #{file}"
		current_dir = file 
		puts "current_dir = #{current_dir}"
	else
		puts "FILE"
		if pic_hash[current_dir].nil? then pic_hash[current_dir.to_s] = [] end  
		pic_hash[current_dir] << file 
		puts "pic_hash[#{current_dir}] = #{file}"
	end 
	#puts "current dir: #{current_dir}\tcurrent_file: #{file}"
end 

puts pic_hash.inspect
		


