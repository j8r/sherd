require "spec"

Spec.before_each do
  Sherd::Logger.output = Sherd::Logger.error = File.open File::NULL, "w"
end

TEST_SHERD_CONFIG = File.read __DIR__ + "/samples/sherd.ini"
TEST_SHERD_LOCK   = File.read __DIR__ + "/samples/sherd.lock"
