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
# username whose photos we're messing with 
username = "skippy39us"


####
# return a hash of the info regarding username
def get_user_info(username) 
	info = flickr.people.findByUsername :username => username
	if @debug.eql? 1 then puts "DEBUG: #{info.inspect}" end 
	return info 
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

	photoset_titles = []
	photosets.each do |current_set|
		photoset_titles << current_set["title"]
	end

	if @debug.eql? 1 then puts photoset_titles.inspect end

	return photoset_titles

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
def upload_photo(photo, title, description, tags) 
	
	photo_id = flickr.upload_photo photo, :title => title, :description => description, :tags => tags
	if @debug.eql? 1 then puts "DEBUG: photo_id = #{photo_id}" end
	return  photo_id

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
# Process a directory of photos
def process_directory(current_dir)
	####
	# Get the photosets
	photoset_titles = get_photo_sets()	 
	
	# Now we have the photosets
	####
	

	####
	# Now what do we do? 
	####
	# see if we have a set called 'current_dir'
	unless photoset_titles.include? current_dir 
		puts "Creating #{current_dir} photoset!"
		create_photoset = true
		set_exists = false 
	else 
		puts "#{current_dir} photoset already exists!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		set_exists = true
	end

	####
	# Upload the photos. 

	# 	Check if the photo exists with photo_exists? method
	# 	if it does not exist in flickr, we can upload it. 

	# 	here's what we do (we just need the name of the photo, which we will also use as
	# 	the title, and description. We'll need to generate the tag, as well, which will 
	# 	be the hash. hmmm....
	#		upload_photo(photo, title, description, tags) 
	
	####

	####
	# if it does not exist, upload it using the upload_photo method. 
end 	

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


####
# This is every photo that we have. 
all_photos = get_all_photos(info["id"])


####
# Suppose we start a new 'sync' of our photo directory to flickr.  We don't want to generate a checksum for EVERY file, every
# time, do we? There should be files that we KNOW are there. Hmmm,....
#####
# YAML stuff
#user_access_list_yaml = YAML.dump(user_access_list)
#yamlfile = File.open("#{cachedir}/#{md5hash}", 'w')
#yamlfile.puts user_access_list_yaml


