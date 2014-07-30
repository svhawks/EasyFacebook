Pod::Spec.new do |s|
  s.name     = 'EasyFacebook'
  s.version  = '0.1.0'
  s.license  = 'zlib'
  s.summary  = 'For developers who do Facebook related work on the server-side, gives them everything they need with just 3 methods.'
  s.homepage = 'https://github.com/isair/EasyFacebook'
  s.authors  = 'Baris Sencan'
  s.source   = { :git => 'https://github.com/isair/EasyFacebook.git', :tag => '0.1.0' }
  s.source_files = 'EasyFacebook/Pod Classes/*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '7.0'

  s.dependency 'Facebook-iOS-SDK', '~>3.16.2'
end
