# frozen_string_literal: true

module Bridgetown
  class PluginManager
    attr_reader :site

    # Create an instance of this class.
    #
    # site - the instance of Bridgetown::Site we're concerned with
    #
    # Returns nothing
    def initialize(site)
      @site = site
    end

    # Require all the plugins which are allowed.
    #
    # Returns nothing
    def conscientious_require
      require_plugin_files
      require_gems
      deprecation_checks
    end

    # Require each of the gem plugins specified.
    #
    # Returns nothing.
    def require_gems
      Bridgetown::External.require_with_graceful_fail(site.gems)
    end

    def self.require_from_bundler
      if !ENV["JEKYLL_NO_BUNDLER_REQUIRE"] && File.file?("Gemfile")
        require "bundler"

        Bundler.setup
        required_gems = Bundler.require(:bridgetown_plugins)
        message = "Required #{required_gems.map(&:name).join(", ")}"
        Bridgetown.logger.debug("PluginManager:", message)
        ENV["JEKYLL_NO_BUNDLER_REQUIRE"] = "true"

        true
      else
        false
      end
    end

    # Require all .rb files
    #
    # Returns nothing.
    def require_plugin_files
      plugins_path.each do |plugin_search_path|
        plugin_files = Utils.safe_glob(plugin_search_path, File.join("**", "*.rb"))
        Bridgetown::External.require_with_graceful_fail(plugin_files)
      end
    end

    # Public: Setup the plugin search path
    #
    # Returns an Array of plugin search paths
    def plugins_path
      if site.config["plugins_dir"].eql? Bridgetown::Configuration::DEFAULTS["plugins_dir"]
        [site.in_source_dir(site.config["plugins_dir"])]
      else
        Array(site.config["plugins_dir"]).map { |d| File.expand_path(d) }
      end
    end

    def deprecation_checks
      pagination_included = (site.config["plugins"] || []).include?("bridgetown-paginate") ||
        defined?(Bridgetown::Paginate)
      if site.config["paginate"] && !pagination_included
        Bridgetown::Deprecator.deprecation_message "You appear to have pagination " \
          "turned on, but you haven't included the `bridgetown-paginate` gem. " \
          "Ensure you have `plugins: [bridgetown-paginate]` in your configuration file."
      end
    end
  end
end