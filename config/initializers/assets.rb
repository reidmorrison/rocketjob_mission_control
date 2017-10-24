Rails.application.config.assets.precompile << Proc.new { |path|
  if path =~ /\.(eot|svg|ttf|woff)\z/
    true
  end
}
