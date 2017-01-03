require 'json'
require 'open-uri'
require 'uri'

class LanguagePack::Helpers::YarnWrapper
  include LanguagePack::ShellHelpers

  class PackageFileParseError < BuildpackError
    def initialize(error)
      msg = "There was an error parsing your package.json, we cannot continue\n"
      msg << error
      super msg
    end
  end

  VENDOR_DIR_PATH      = './vendor'

  def initialize
    @vendor_dir_path =  ENV['VENDOR_DIR_PATH'] || VENDOR_DIR_PATH
    @vendor_path = Pathname.new(@vendor_dir_path).realpath
    @yarn_fetcher = LanguagePack::Fetcher.new("https://yarnpkg.com/downloads/")
    @node_fetcher = LanguagePack::Fetcher.new("https://nodejs.org/dist/")
  end

  def install_node_modules_and_dependencies
    FileUtils.chdir @vendor_path do
      if node_app?
        topic "yarn.lock file detected"
        install_node
        install_yarn
        install_packages
      end
    end
  end

  def node_app?
    FileUtils.chdir @vendor_path do
      return yarn_lock_file_path && yarn_lock_file_path
    end
  end

  private

  def install_yarn
    topic "installing yarn #{yarn_version}"
    @yarn_fetcher.fetch_untar("#{yarn_version}/yarn-v#{yarn_version}.tar.gz", "dist/")
    FileUtils.cp_r("dist/.", "./yarn")
    FileUtils.rm_rf("dist")
  end

  def install_node
    untar_dir = "node-v#{node_version}-linux-x64"
    topic "installing #{untar_dir}"
    @node_fetcher.fetch_untar("v#{node_version}/#{untar_dir}.tar.gz", "#{untar_dir}/bin")
    FileUtils.mkdir("./node")
    FileUtils.cp_r("#{untar_dir}/.", "./node")
    FileUtils.rm_rf(untar_dir)
  end

  def install_packages
    topic "installing node modules"
    run! "../bin/yarn install"
    topic "installing node packages done"
  end

  def yarn_version
    @yarn_version ||= open("https://semver.herokuapp.com/yarn/resolve/#{provided_yarn_version}")
  end

  def node_version
    @node_version ||= open("https://semver.herokuapp.com/node/resolve/#{provided_node_version}")
  end

  def parsed_package_file
    @parsed_package_file ||= begin
      json = File.read(package_dot_json_file_path)
      JSON.parse(json)
    end
  end

  def engine_config
    @engine_config ||= parsed_package_file.fetch('engines', {})
  end

  def provided_node_version
    engine_config['node']
  end

  def provided_yarn_version
    engine_config['yarn']
  end

  def yarn_lock_file_path
    Dir["yarn.lock"].first
  end

  def package_dot_json_file_path
    Dir["package.json"].first
  end

  def instrument title
    topic title
    yield
  end

  def open uri
    super(URI.escape(uri)).read
  end

end
