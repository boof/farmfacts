require "#{ File.dirname __FILE__ }/../../config/environment" unless defined? Rails

class AssetMetal

  NoAssets = [ 200, {}, [] ]
  NotFoundResponse = Rails::Rack::Metal::NotFoundResponse

  def self.call(env)
    if env['PATH_INFO'] =~ /^\/images/ then NoAssets else NotFoundResponse end
  end
end
