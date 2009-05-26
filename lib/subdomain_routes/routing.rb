module SubdomainRoutes
  module Routing
    module RouteSet
      include SplitHost
      
      module Mapper
        def subdomain(*subdomains, &block)
          options = subdomains.extract_options!
          if subdomains.empty?
            if subdomain = options.delete(:proc)
              subdomain_options = { :subdomains => { :proc => subdomain } }
              name = subdomain
            else
              raise ArgumentError, "Please specify at least one subdomain!"
            end
          else
            subdomains.map!(&:to_s)
            subdomains.uniq!
            subdomains.compact.each do |subdomain|
              raise ArgumentError, "Illegal subdomain: #{subdomain.inspect}" unless subdomain.to_s =~ /^[0-9a-z\-]*$/
            end
            if subdomains.include? ""
              raise ArgumentError, "Can't specify a nil subdomain unless you set Config.domain_length!" unless Config.domain_length
            end
            name = subdomains.reject(&:blank?).first
            subdomain_options = { :subdomains => subdomains }
          end
          name = options.delete(:name) if options.has_key?(:name)
          subdomain_options.merge! :name_prefix => "#{name}_", :namespace => "#{name}/" unless name.blank?
          with_options(subdomain_options.merge(options), &block)
        end
        alias_method :subdomains, :subdomain
      end

      def self.included(base)
        base.alias_method_chain :extract_request_environment, :subdomain
        base.alias_method_chain :add_route, :subdomains
      end
      
      def extract_request_environment_with_subdomain(request)
        extract_request_environment_without_subdomain(request).merge(:subdomain => subdomain_for_host(request.host))
      end
    
      def add_route_with_subdomains(*args)
        options = args.extract_options!
        if subdomains = options.delete(:subdomains)
          options[:conditions] ||= {}
          options[:conditions][:subdomains] = subdomains
          options[:requirements] ||= {}
          options[:requirements][:subdomains] = subdomains
        end
        with_options(options) { |routes| routes.add_route_without_subdomains(*args) }
      end
      
      def verify_subdomain(name, &block)
        (class << self; self; end).send(:define_method, "#{name}_subdomain?", &block)
        # TODO: test this
      end

      def generate_subdomain(name, &block)
        (class << self; self; end).send(:define_method, "#{name}_subdomain", &block)
        # TODO: test this
      end
    end
  
    module Route
      def self.included(base)
        base.alias_method_chain :recognition_conditions, :subdomains
      end
      
      def recognition_conditions_with_subdomains
        result = recognition_conditions_without_subdomains
        case conditions[:subdomains]
        when Array
          result << "conditions[:subdomains].include?(env[:subdomain])"
        when Hash
          if subdomain = conditions[:subdomains][:proc]
            method = "#{subdomain}_subdomain?"
            result << %Q{(ActionController::Routing::Routes.#{method}(env[:subdomain]) if ActionController::Routing::Routes.respond_to?(:#{method}))}
          end
        end
        result
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SubdomainRoutes::Routing::RouteSet::Mapper
ActionController::Routing::RouteSet.send :include, SubdomainRoutes::Routing::RouteSet
ActionController::Routing::Route.send :include, SubdomainRoutes::Routing::Route
