require 'persistent_httparty'

class BlogAccessor
  include HTTParty
  persistent_connection_adapter
  def self.blogs
    self.get("#{host}/").parsed_response
  end

  private
  def self.host
    ENV['BLOG_ACCESSOR_URL']
  end
end
