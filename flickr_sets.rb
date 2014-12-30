#!/usr/bin/env ruby 

require 'flickraw'
require 'find'
require './flickr_init' 


debug = 1
#####
# Base upload directory
base_dir = "/stuff/Pictures/2012"


#####
# username whose photos we're messing with 
username = "skippy39us"


####
# return a hash of the info regarding username
def get_user_info(debug, username) 
	info = flickr.people.findByUsername :username => 'skippy39us'
	if debug.eql? 1 then puts info.inspect end 
	return info 
end 


####
# return a list of photosets
def get_photo_sets(debug)
	####
	# Get list of all photosets - in an array
	photosets = flickr.photosets.getList

	####
	# List each photoset title

	photoset_titles = []
	photosets.each do |current_set|
		photoset_titles << current_set["title"]
	end

	if debug.eql? 1 then puts photoset_titles.inspect end

	return photoset_titles

end 


####
# Given a user, return a list of all photos
def get_all_photos(debug, username)
	all_photos = flickr.people.getPhotos(:user_id => username)
	if debug.eql? 1 then puts all_photos.inspect end 
end

####
# Given a photoset, return list of photos. 
def get_photo_list(debug, set_id) 
	photo_list = flickr.photosets.getPhotos(:photoset_id => set_id)
	if debug.eql? 1 then puts photo_list.inspect end
	return photo_list
end 


####
# Given a photo and a set, does it exist already? 
def photo_exist?(debug, photo, set) 
end 


####
# upload a photo and return the photo id
def upload_photo(debug, photo, title, description) 

	return  photo_id
end 


####
# Create a checksum of a file 
def checksum_photo(debug, photo)
	#####
	# So we read the file, and then create a checksum. 
	# We can then use that checksum to tag the photo when we upload it to flickr. 
	#	Like this: 
	#		flickr.photos.addTags(:photo_id => photo.id, :tags => checksum)

	checksum = Digest::MD5.hexdigest(File.read(photo))
	return checksum 
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


get_photo_sets(debug) 
puts
puts "#####"


info = get_user_info(debug, username) 

get_all_photos(debug, info["id"])
