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

  it "converts to Shred lock" do
    Sherd::Shards::Lock.from_yaml TEST_SHARDS_LOCK
    # config = Sherd::Config.new TEST_INI_CONFIG
    # config.build.should eq TEST_INI_CONFIG
  end
end
