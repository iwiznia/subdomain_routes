module SubdomainRoutes
  module Routing
    module RouteSet
      include SplitHost
      
      def self.included(base)
        [ :extract_request_environment, :add_route, :clear!, :call ].each { |method| base.alias_method_chain method, :subdomains }
      end
      
      def extract_request_environment_with_subdomains(request)
        extract_request_environment_without_subdomains(request).merge(:subdomain => subdomain_for_host(request.host))
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
      
      def subdomain_procs
        @subdomain_procs ||= SubdomainRoutes::ProcSet.new
      end

      def recognize_subdomain(name, &block)
        subdomain_procs.add_recognizer(name, &block)
      end
      
      def clear_with_subdomains!
        subdomain_procs.clear!
        clear_without_subdomains!
      end
      
      def call_with_subdomains(*args)
        subdomain_procs.flush! unless SubdomainRoutes::Config.manual_flush
        call_without_subdomains(*args)
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
            result << %Q{ActionController::Routing::Routes.subdomain_procs.recognize(#{subdomain.inspect}, env[:subdomain])}
          end
        end
        result
      end
    end
  end
end

ActionController::Routing::RouteSet.send :include, SubdomainRoutes::Routing::RouteSet
ActionController::Routing::Route.send :include, SubdomainRoutes::Routing::Route
