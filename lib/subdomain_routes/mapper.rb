module SubdomainRoutes
  module Routing
    module RouteSet
      module Mapper
        def subdomain(*subdomains, &block)
          options = subdomains.extract_options!.dup
          if subdomains.empty?
            if model = options.delete(:model)
              raise ArgumentError, "Invalid model name" if model.blank?
              models = model.to_s.downcase.pluralize
              model = models.singularize
              model_col = options.delete(:column) || model.foreign_key.to_sym
              subdomain_options = { :subdomains => model_col }
              name = options.has_key?(:name) ? options.delete(:name) : model
            else
              raise ArgumentError, "Please specify at least one subdomain!"
            end
          else
            subdomains.map!(&:to_s)
            subdomains.map!(&:downcase)
            subdomains.uniq!
            subdomains.compact.each do |subdomain|
              raise ArgumentError, "Illegal subdomain format: #{subdomain.inspect}" unless subdomain.blank? || SubdomainRoutes.valid_subdomain?(subdomain)
            end
            if subdomains.include? ""
              raise ArgumentError, "Can't specify a nil subdomain unless you set Config.domain_length!" unless Config.domain_length
            end
            subdomain_options = { :subdomains => subdomains }
            name = subdomains.reject(&:blank?).first
            name = options.delete(:name) if options.has_key?(:name)
          end
          name = name.to_s.downcase.gsub(/[^(a-z0-9)]/, ' ').squeeze(' ').strip.gsub(' ', '_') unless name.blank?
          subdomain_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" unless name.blank?
          with_options(subdomain_options.merge(options), &block)
        end
        alias_method :subdomains, :subdomain

        def host(*hosts, &block)
          options = hosts.extract_options!.dup
          if hosts.empty?
            if model = options.delete(:model)
              raise ArgumentError, "Invalid model name" if model.blank?
              models = model.to_s.downcase.pluralize
              model = models.singularize
              model_id = model.foreign_key.to_sym
              host_options = { :hosts => model_id }
              name = options.has_key?(:name) ? options.delete(:name) : model
            else
              raise ArgumentError, "Please specify at least one subdomain!"
            end
          else
            hosts.map!(&:to_s)
            hosts.map!(&:downcase)
            hosts.uniq!
            hosts.compact.each do |host|
              raise ArgumentError, "Illegal host format: #{host.inspect}" unless host.blank? || SubdomainRoutes.valid_host?(host)
            end
            if hosts.include? ""
              raise ArgumentError, "Can't specify a nil host unless you set Config.domain_length!" unless Config.domain_length
            end
            host_options = { :hosts => hosts }
            name = hosts.reject(&:blank?).first
            name = options.delete(:name) if options.has_key?(:name)
          end
          name = name.to_s.downcase.squeeze(' ').strip.gsub(' ', '_') unless name.blank?
          host_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" unless name.blank?
          with_options(host_options.merge(options), &block)
        end
        alias_method :hosts, :host
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SubdomainRoutes::Routing::RouteSet::Mapper

