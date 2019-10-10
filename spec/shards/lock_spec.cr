require "../spec_helper"
require "../../src/shards"

TEST_SHARDS_LOCK = File.read __DIR__ + "/../samples/shard.lock"

describe Sherd::Config do
  it "parses a package lock file" do
    Sherd::Shards::Lock.from_yaml TEST_SHARDS_LOCK
  end

  it "builds a package lock file" do
    Sherd::Shards::Lock.from_yaml(TEST_SHARDS_LOCK).to_yaml.should eq TEST_SHARDS_LOCK
  end

  it "converts to Sherd::Lock" do
    config = Sherd::Shards::Lock.from_yaml TEST_SHARDS_LOCK
    config.to_sherd.build.should eq <<-LOCK
    [first]
    path = github.com/user1/first
    version = 0.1.2
    hash = sha512:

    [second]
    path = gitlab.com/user2/second
    version = 0.4.0
    hash = sha512:


    LOCK
  end
end
