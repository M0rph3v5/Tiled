Pod::Spec.new do |s|
  s.name         = "Tiled"
  s.version      = "0.1.0"
  s.license      = "MIT"

  s.summary      = "A CATiledLayer implementation to easily view high resolution (tiled) images in a zooming UIScrollView."

  s.description  = <<-DESC
Everyone who has ever dealt with CATiledLayer knows it can take some time to wrap your head around it, this pod simplifies this by having a drop in TilingScrollView which you populate through the datasource to view your tiled content.

As simple as that.
                   DESC

  s.authors           = { "Benjamin de Jager" => "me@m0rph3v5.com" }
  s.social_media_url  = "https://twitter.com/m0rph3v5"
  s.homepage          = "https://github.com/m0rph3v5/Tiled"

  s.ios.deployment_target = '8.0'

  s.source          = { :git => "https://github.com/m0rph3v5/Tiled.git", :tag => s.version }
  s.requires_arc    = true
  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files  = "src/Tiled"
  end
end
