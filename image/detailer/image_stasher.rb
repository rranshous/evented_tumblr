require 'base64'
require 'httparty'
require 'persistent_httparty'

class ImageStasher
  include HTTParty
  persistent_connection_adapter
  def self.get_data image_href
    puts "HOST: #{host}"
    image_href_encoded = Base64.urlsafe_encode64(image_href)
    HTTParty.get("#{host}/#{image_href_encoded}").parsed_response
  end

  private
  def self.host
    ENV['IMAGE_STASHER_URL']
  end
end
