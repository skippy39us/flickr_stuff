#!/usr/bin/env ruby 

require 'flickraw'
require 'digest/sha1'
require 'find'
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
# return a hash of the info regarding username
def get_user_info(username) 
	info = flickr.people.findByUsername :username => username
	if @debug.eql? 1 then puts "DEBUG: #{info.inspect}" end 
	return info 
end 

####
# Suck in the yaml of checksums, if it exists
@checksum_hash = {}
if File.exists?("/home/seidenbt/flickr_yaml")
	@checksum_hash = YAML.load_file("/home/seidenbt/flickr_yaml")	
end 
		


###
# return a list of tags for a photo
def get_tags(photo_id)
	#####
	# tags is an empty array at first
	tags = []
	####
	# there's alot of metadata that is stored with the tags for each
	# photo
	tag_info = flickr.tags.getListPhoto(:photo_id => 'photo_id')
	if @debug.eql? 1 then puts "DEBUG: tag_info = #{tag_info.inspect}" end 

	####
	# Lets go through all of the tag data for this photo id, and 
	# just spit out the tags themselves. I think thats all we 
	# care about. 
	tag_info["tags"].each do |meta_tag|  
		tags < meta_tag["_content"]	
	end 
	if @debug.eql? 1 then puts "DEBUG: tags = #{tags.inspect}" end

	return tags 
end
	

####
# return a list of photosets
def get_photo_sets()
	####
	# Get list of all photosets - in an array
	photosets = flickr.photosets.getList

	####
	# List each photoset title

	#photoset_titles = []
	#photosets.each do |current_set|
	#	photoset_titles << current_set["title"]
	#end

	#if @debug.eql? 1 then puts photoset_titles.inspect end

	return photosets

end 


####
# Given a user, return a list of all photos
def get_all_photos(userid)

	all_photos = [] 
	
	####
	# Note that this only gives 100 photos at a time. We can change that
	# to a maximum of 500 per page.  We have 
	# to iterate through every 'page' of photos that flickr has for us, 
	# each time increasing the page number.  I wonder how I can get the maximum
	# number of pages. 

	####
	# set this to a non empty array with nothing in it.. :-D 
	current_page_photos = ["empty"] 

	####
	# our current page of photos
	page = 0 
	

	####
	# While the current page has more than 0 pictures on it, essentially
	while current_page_photos.length > 0 	
		if @debug.eql? 1 then puts "DEBUG: Page #{page}" end 
		page = page + 1
		current_page_photos = flickr.photos.search(:user_id => userid, :per_page => '500', :page => page) 
		if @debug.eql? 1 then puts "DEBUG: current_page_photos = #{current_page_photos.inspect}" end 
		if @debug.eql? 1 then puts "DEBUG: current_page_photos.length = #{current_page_photos.length}" end 

		####
		# Add those photos to the list of previously aquired photos. 
		all_photos << current_page_photos
	end 		
	
	if @debug.eql? 1 then puts all_photos.inspect end 

	#####
	# It would be cool if we could generate a data structure that included the TAGS as keys, pointing the pic that
	# used that tag.  Since most of our tags will be unique, this will work. If a tag DOES repeat
	# (in a non-sha tag, for example) then we can just have an array of photos that the tag applies to. 
	# this is a little backwards, but i think it will work. Do it here, before returning all_photos.


	#
	#
	####
	return all_photos
end

####
# Given a photoset, return list of photos. 
def get_photo_list(set_id) 
	photo_list = flickr.photosets.getPhotos(:photoset_id => set_id)
	if @debug.eql? 1 then puts photo_list.inspect end
	return photo_list
end 


####
# Given a photo and a set, does it exist already? 
def photo_exist?(photo) 
	### 
	# compare sha of photo with the sha tag of EVERY photo that we've
	# already uploaded. 
	# 	how do we do that? 
	# 		 
	# return true if that sha already exits as a tag. 
	# return false if it dunna. 
	sha = checksum_photo(photo) 
	####
	# 	
end 


####
# upload a photo and return the photo id
def upload_photo(photo, title, description, tags, create_photo, current_dir) 
	
	photo_id = flickr.upload_photo photo, :title => title, :description => description, :tags => tags
	if @debug.eql? 1 then puts "DEBUG: photo_id = #{photo_id}" end

				
	####
	# Move the photo into the appropriate photoset. 

	
	return  photo_id

end 


def add_photo_to_set(photo_id, current_photoset_id) 
	if @debug.eql? 1 then puts "DEBUG: adding photo #{photo_id} to #{current_photoset_id}"  end 
	flickr.photosets.addPhoto :photoset_id => current_photoset_id, :photo_id => photo_id
end 

####
# Create a checksum of a file 
def checksum_photo(photo)
	#####
	# So we read the file, and then create a checksum. 
	# We can then use that checksum to tag the photo when we upload it to flickr. 
	#	Like this: 
	#		flickr.photos.addTags(:photo_id => photo.id, :tags => checksum)

	checksum = Digest::SHA1.hexdigest(File.read(photo))
	if @debug.eql? 1 then puts "DEBUG: checksum for #{photo} is #{checksum}" end 
	return checksum 
end

####
# Create a photoset and return the photoset id. 
def make_photoset(current_dir, photo_id)
	if @debug.eql? 1 then puts "DEBUG: flickr.photosets.create :title => #{current_dir}, :description => #{current_dir}, :primary_photo_id => #{photo_id}" end 

	current_photoset_hash = flickr.photosets.create :title => current_dir, :description => current_dir, :primary_photo_id => photo_id
	if @debug.eql? 1 then puts "DEBUG: current_photoset_hash = #{current_photoset_hash.inspect}" end 

	current_photoset_id = current_photoset_hash["id"]
	if @debug.eql? 1 then puts "DEBUG: current_photoset_id = #{current_photoset_id}" end 
	return current_photoset_id
end

####
# Process a directory of photos
def process_directory(base_dir)
	create_photoset = true
	current_photoset_id = ""
	current_checksum = ""
	current_dir = ""
	upload_photo = false
	tags = [] 
	####
	# Get the photosets
	if @debug.eql? 1 then puts "DEBUG: processing #{base_dir}" end 
	photosets = get_photo_sets()	 

	photoset_ids = []
	photoset_titles = []
	photosets.each do |current_set|
		photoset_titles << current_set["title"]
		photoset_ids    << current_set["id"]
	end



	# Now we have the photosets
	####
	
	Find.find(base_dir) do |current_file|
		full_path = ""
		if File.directory?(current_file)
			####
			# seperate the name of the directory only. We can use this as our photo_set name. :-) 
			###
			# obviously, full_path is just that.
			full_path = current_file
			####
			# this is the current directory - the immediate directory, without the full 
			# path behind it. 
			# 	/opt/blah/blah2/blah3 would equal "blah3" only. 
			current_dir = current_file.split('/').last
			####
			# see if we have a set called 'current_dir'

			photosets.each do |current_set|
				if current_set.title.eql? current_dir 
					puts "#{current_dir} photoset exists!"
					create_photoset = false
					current_photoset_id = current_set.id
				end 
			end 

		else 
			####
			# We are dealing with an actual file.

			####
			# Upload the photos. 
	
			# 	Check if the photo exists with photo_exists? method
			# 	if it does not exist in flickr, we can upload it. 
	
			# 	here's what we do (we just need the name of the photo, which we will also use as
			# 	the title, and description. We'll need to generate the tag, as well, which will 
			# 	be the hash. hmmm....
			#		upload_photo(photo, title, description, tags) 


			####
			# Go through each of the @checksum_hash keys, and see if any of them refer
			# to a filename that equals current_file. 
			# If there are no filename matches, take a new checksum

			# If it _DOES_ have a match, 
			# check the mtime of current_file, and compare it to 
			# @checksum_hash[current_checksum][:mod_time]. 

			# If the mtimes are different  take a new checksum. 

			# if they aren't, then we don't have to upload the file. 


			####
			# basically assigns the matching sub-hash to match if the current_file
			# is already in place. 

			match = @checksum_hash.select{|key, hash| hash[:current_file] == current_file}
			if match.empty?
				###
				# The file has not been checksum'd yet. 
				# we need to populate a new checksum key. 
				if @debug.eql? 1 then puts "DEBUG: #{current_file} is a new file in these parts..."  end 
				current_checksum = checksum_photo(current_file)
				new_modtime  = File.mtime(current_file)

				if @checksum_hash[current_checksum].nil? then @checksum_hash[current_checksum] = {} end 
				@checksum_hash[current_checksum][:mod_time] = new_modtime
				@checksum_hash[current_checksum][:current_file] = current_file
				upload_file = true

			else 
				mtime_match = @checksum_hash.select{|key, hash| hash[:mod_time] == File.mtime(current_file)}
				if mtime_match.empty? 
					#####
					# If we're here, the file _does_ exist, but...
					# we have a new modtime. 
					# WE MUST remove the old checksum key. 
					# We need to populate a checksum key. 
					
					current_checksum = checksum_photo(current_file)
					new_modtime  = File.mtime(current_file)

					#####
					# delete the old checksum from @checksum_hash. 
					if @debug.eql? 1 then puts "DEBUG: removing checksum #{match.keys.first} from @checksum_hash" end 
					@checksum_hash.delete(match.keys.first) 
					###
					# the hash is populated here. 
					if @checksum_hash[current_checksum].nil? then @checksum_hash[current_checksum] = {} end 
					@checksum_hash[current_checksum][:mod_time] = new_modtime
					upload_file = true
				end
			end 
				
				

			#####
			# here are the tags.  Right now its just a checksum.
			tags <<  current_checksum
		
				
			####
			# Upload the file, finally. 
			if @debug.eql? 1 then puts "DEBUG: create_photoset = #{create_photoset}" end 
			if upload_file.eql? true 
				photo_id = upload_photo(current_file, current_file, current_file, tags, create_photoset, current_dir)
				if create_photoset.eql? true
					current_photoset_id = make_photoset(current_dir, photo_id) 
				end 	

				####
				# add photo to a set.  	
				add_photo_to_set(photo_id, current_photoset_id) 
			end

		

		end
	end 	
end 

####
# Suppose we start a new 'sync' of our photo directory to flickr.  We don't want to generate a checksum for EVERY file, every
# time, do we? There should be files that we KNOW are there. Hmmm,....
#
# In theory, there can only be unique photo file names in any directory. So if we keep a yaml of a hash of directory name keys
# which point to hashes of photo filename -> checksum values, we should be able to tell if we need to create a checksum for a file
# in question.  Yeah. 
#
#
# Actually, lets try checksum => filename hashes. How do we do that? 




#####
# YAML stuff
#user_access_list_yaml = YAML.dump(user_access_list)
#yamlfile = File.open("#{cachedir}/#{md5hash}", 'w')
#yamlfile.puts user_access_list_yaml
#yamlfile.close 
#YAML.load_file("/path/to/yaml_file")



#set_exists = false 
#create_photoset = false 
#current_photoset_id = ""
#current_dir = ""



#Find.find(base_dir) do |current_file|
#	if File.directory?(current_file)
#		####
#		# seperate the name of the directory only
#		current_dir = current_file.split('/').last
#		####
#		# see if we have a set called 'current_dir'
#		unless photoset_titles.include? current_dir 
#			puts "Creating #{current_dir} photoset!"
#			create_photoset = true
#			set_exists = false 
#		else 
#			puts "#{current_dir} photoset already exists!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#			set_exists = true
#		end
#	else 
#		####
#		# If the file isn't a JPG, we skip it. 
#		unless current_file =~ /jpg$/i 
#			next
#		end 
#		unless set_exists.eql? true
#			puts "\tUploading #{current_file}"
#			####
#			# upload the file, and get a photo_id in return
#			
#			photo_id = flickr.upload_photo current_file, :title => current_file, :description => current_file
#
#			if create_photoset.eql? true 
#				puts "Creating photoset #{current_dir} with this primary photo: #{current_file}" 	
#				current_photoset_hash = flickr.photosets.create :title => current_dir, :description => current_dir, :primary_photo_id => photo_id
#				current_photoset_id = current_photoset_hash["id"]
#				puts "current_photoset = #{current_photoset_id}" 
#			end 	
#			####
#			# move the photo_id above into the appropriate photoset. 
#			unless create_photoset.eql? true
#				puts "\tadding #{current_file} to #{current_dir} (#{current_photoset_id})" 
#				
#				flickr.photosets.addPhoto :photoset_id => current_photoset_id, :photo_id => photo_id
#			else
#				create_photoset = false 
#			end 		
#		end 
#	end
#end	


info = get_user_info(username) 
#get_photo_sets(debug) 
puts
puts "#####"

process_directory("/home/seidenbt/test")

####
# This is every photo that we have. 
all_photos = get_all_photos(info["id"])

checksum_hash_yaml = YAML.dump(@checksum_hash)
yamlfile = File.open("/home/seidenbt/flickr.yml", 'w')
yamlfile.puts checksum_hash_yaml
yamlfile.close



