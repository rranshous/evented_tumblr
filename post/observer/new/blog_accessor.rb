require 'persistent_httparty'

class BlogAccessor
  include HTTParty
  persistent_connection_adapter
  def self.blogs
    self.get("#{host}/").parsed_response
  end

  private
  def self.host
    # most strait forward way to set
    url = ENV['BLOG_ACCESSOR_URL']
    # check for docker link vars
    if ENV['BLOGACCESSOR_PORT']
      host_port = ENV['BLOGACCESSOR_PORT'].split('//').last
      url = "http://#{host_port}"
    end
    url
  end
end
