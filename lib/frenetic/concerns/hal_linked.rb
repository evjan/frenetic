require 'active_support/concern'
require 'addressable/template'

class Frenetic
  module HalLinked
    extend ActiveSupport::Concern

    module ClassMethods
      def links
        api.description['_links']
      end

      def member_url( params = {} )
        url = links[namespace] or raise HypermediaError, %Q{No Hypermedia GET Url found for the resource "#{namespace}"}

        if url['templated']
          tmpl = Addressable::Template.new url['href']

          params = { id:params } unless params.is_a? Hash

          tmpl.expand( params ).to_s
        else
          url['href']
        end
      end
    end
  end
end