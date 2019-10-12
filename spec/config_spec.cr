require "./spec_helper"
require "../src/config.cr"

describe Sherd::Config do
  it "parses a package config file" do
    Sherd::Config.new TEST_SHERD_CONFIG
  end

  it "builds a package config file" do
    config = Sherd::Config.new TEST_SHERD_CONFIG
    config.build.should eq TEST_SHERD_CONFIG
  end

  describe "config fields" do
    config = Sherd::Config.new TEST_SHERD_CONFIG

    describe "package section" do
      it "parses the name" { config.package.name.should eq "test" }
      it "parses the version" { config.package.version.should eq "0.0.1" }
      it "parses the description" { config.package.description.should eq "Some description" }
      it "parses the license" { config.package.license.should eq "ISC" }
    end

    it "parses the authors" { config.authors.not_nil!["main"].should eq "Foo" }

    it "parses the scripts" do
      config.scripts.not_nil!.should eq({
        "postinstall" => "make something",
        "build"       => "src/test.cr",
        "build:other" => "src/other.cr",
      })
    end

    {dependencies: config.dependencies, dev_dependencies: config.dev_dependencies}.each do |name, deps|
      describe "#{name} section" do
        it "parses one without a version" do
          metadata = Sherd::Config::DependencyMetadata.new "github.com/user1/first", nil
          dependency = deps.not_nil!["first"]
          dependency.should eq metadata
          dependency.uri.should eq URI.new(host: "github.com", path: "/user1/first")
        end

        it "parses one with a version" do
          metadata = Sherd::Config::DependencyMetadata.new "gitlab.com/user2/second", "~5.0.0"
          dependency = deps.not_nil!["second"]
          dependency.should eq metadata
          dependency.uri.should eq URI.new(host: "gitlab.com", path: "/user2/second")
        end
      end
    end
  end

  describe Sherd::Config::DependencyMetadata do
    it "parses a path without a scheme" do
      metadata = Sherd::Config::DependencyMetadata.new "github.com/user/test"
      metadata.uri.should eq URI.new(host: "github.com", path: "/user/test")
    end

    it "parses a path with a scheme" do
      metadata = Sherd::Config::DependencyMetadata.new "https://github.com/user/test"
      metadata.uri.should eq URI.new(scheme: "https", host: "github.com", path: "/user/test")
    end
  end
end
