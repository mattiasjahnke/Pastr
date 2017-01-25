Pod::Spec.new do |s|
  s.name = 'Pastr'
  s.version = '0.1.0'
  s.license = 'MIT'
  s.summary = 'Module wrapping the Pastebin API'
  s.homepage = 'https://github.com/mattiasjahnke/Pastr'
  s.social_media_url = 'https://instagram.com/engineerish'
  s.authors = { 'Mattias Jähnke' => 'hello@engineerish.com' }
  s.source = { :git => 'https://github.com/mattiasjahnke/Pastr.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Source/*.swift'
end
