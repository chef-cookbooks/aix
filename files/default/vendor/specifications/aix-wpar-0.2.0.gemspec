# -*- encoding: utf-8 -*-
# stub: aix-wpar 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "aix-wpar".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alain Dejoux".freeze]
  s.date = "2020-03-18"
  s.description = "A wrapper for the AIX WPAR administration.".freeze
  s.email = ["adejoux@djouxtech.net".freeze]
  s.homepage = "https://github.com/adejoux/aix-wpar".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A ruby library wrapper for the AIX WPAR administration.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-shellout>.freeze, ["> 2", "< 4"])
    else
      s.add_dependency(%q<mixlib-shellout>.freeze, ["> 2", "< 4"])
    end
  else
    s.add_dependency(%q<mixlib-shellout>.freeze, ["> 2", "< 4"])
  end
end
