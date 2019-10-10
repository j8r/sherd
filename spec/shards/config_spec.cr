require "../spec_helper"

TEST_SHARDS_CONFIG = File.read __DIR__ + "/../samples/shard.yml"

describe Sherd::Config do
  it "parses a package config file" do
    Sherd::Shards::Config.from_yaml TEST_SHARDS_CONFIG
  end

  it "builds a package config file" do
    Sherd::Shards::Config.from_yaml(TEST_SHARDS_CONFIG).to_yaml.should eq TEST_SHARDS_CONFIG
  end

  it "converts to Sherd::Config" do
    config = Sherd::Shards::Config.from_yaml TEST_SHARDS_CONFIG
    config.to_sherd.build.should eq <<-CONFIG
    [package]
    name = test
    version = 0.0.1
    description = Some description
    license = ISC

    [authors]
    author0 = Foo

    [dependencies]
    first = github.com/user1/first ~5.0.0
    second = gitlab.com/user2/second ~5.0.0

    [dev_dependencies]
    first = github.com/user1/first ~5.0.0
    second = gitlab.com/user2/second ~5.0.0

    [scripts]
    postinstall = make something
    build = src/test.cr
    build:other = src/other.cr


    CONFIG
  end
end
