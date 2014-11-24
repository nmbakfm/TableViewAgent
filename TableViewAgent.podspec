
Pod::Spec.new do |s|
  s.name         = "TableViewAgent"
  s.version      = "0.3.1"
  s.summary      = "library that wraps the delegate and datesource of UITableView"
  s.homepage     = "https://github.com/akuraru/TableViewAgent"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "akuraru" => "akuraru@gmail.com" }
  s.ios.deployment_target = '7.0'
  s.source       = { :git => "#{s.homepage}.git", :tag => s.version }
  s.source_files  = 'lib/**/*.{swift, h, m}'
  s.requires_arc = true
end
