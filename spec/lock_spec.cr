require "./spec_helper"
require "../src/lock.cr"

describe Sherd::Lock do
  it "parses a package lock file" do
    Sherd::Lock.new TEST_SHERD_LOCK
  end

  it "builds a package lock file" do
    lock = Sherd::Lock.new TEST_SHERD_LOCK
    lock.build.should eq TEST_SHERD_LOCK
  end

  it "parses a locked dependency" do
    lock = Sherd::Lock.new TEST_SHERD_LOCK
    metadata = Sherd::Lock::DependencyLock.new "github.com/user1/first", SemanticVersion.parse("0.1.2"), "a1b2c3"
    dependency = lock.dependencies["first"]?.not_nil!
    dependency.should eq metadata
    dependency.uri.should eq URI.new(host: "github.com", path: "/user1/first")
  end

  describe Sherd::Lock::DependencyLock do
    it "parses a path without a scheme" do
      deplock = Sherd::Lock::DependencyLock.new "github.com/user/test", SemanticVersion.new(0, 0, 0), ""
      deplock.uri.should eq URI.new(host: "github.com", path: "/user/test")
    end

    it "parses a path with a scheme" do
      deplock = Sherd::Lock::DependencyLock.new "https://github.com/user/test", SemanticVersion.new(0, 0, 0), ""
      deplock.uri.should eq URI.new(scheme: "https", host: "github.com", path: "/user/test")
    end
  end
end
