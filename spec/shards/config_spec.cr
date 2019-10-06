require "../spec_helper"

TEST_SHARDS_CONFIG = File.read __DIR__ + "/../samples/shard.yml"

describe Sherd::Config do
  it "parses a package config file" do
    Sherd::Shards::Config.from_yaml TEST_SHARDS_CONFIG
  end

  it "builds a package config file" do
    Sherd::Shards::Config.from_yaml(TEST_SHARDS_CONFIG).to_yaml.should eq TEST_SHARDS_CONFIG
  end

  it "converts to Shred config" do
    Sherd::Shards::Config.from_yaml TEST_SHARDS_CONFIG
    # config = Sherd::Config.new TEST_INI_CONFIG
    # config.build.should eq TEST_INI_CONFIG
  end
end
