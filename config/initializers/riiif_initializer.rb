#Riiif::Image.file_resolver.base_path = '/Users/erjhome/RubymineProjects/Amy_Natural_History/iiif-images'

Riiif::Image.file_resolver.base_path = '/var/www/html/bartram-images'

Riiif::ImagesController.class_eval do
       #skip_before_action :authenticate_user!, only: [:show, :info]
       before_action :authenticate_user!
end

