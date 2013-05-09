require 'active_support/concern'
require 'addressable/template'

class Frenetic
  module HalLinked
    extend ActiveSupport::Concern

    def links
      @params['_links']
    end

    def member_url( params = {} )
      resource = @resource_type || self.class.to_s.demodulize.underscore

      link = links[resource] || links['self'] or raise HypermediaError, %Q{No Hypermedia GET Url found for the resource "#{resource}"}

      self.class.parse_link link, params
    end

    module ClassMethods
      def links
        api.description['_links']
      end

      def member_url( params = {} )
        link = links[namespace] or raise HypermediaError, %Q{No Hypermedia GET Url found for the resource "#{namespace}"}

        parse_link link, params
      end

      def parse_link( link, params = {} )
        if link['templated']
          expand_link link, params
        else
          link['href']
        end
      end

    private

      def expand_link( link, params )
        tmpl = Addressable::Template.new link['href']

        if params && !params.is_a?(Hash)
          params = infer_url_template_values tmpl, params
        end

        tmpl.expand( params ).to_s
      end

      def infer_url_template_values( tmpl, params )
        key = tmpl.variables.first

        { key => params }
      end

    end
  end
end