module Sherd::Shards::Converter
  def self.keys_to_path_or_version(keys : Hash(String, String)) : Tuple(String, String | Git::Revision | Nil)
    path = nil
    rev_or_version = nil
    keys.each do |key, value|
      case key
      when "github", "gitlab", "bitbucket"
        path = key + ".com/" + value
      when "path", "git" then path = value
      when "version"
        sign, _, version = value.partition ' '
        sign = "~" if sign == "~>"
        rev_or_version = sign + version
      when "commit" then rev_or_version = Git::Commit.new value
      when "tag"    then rev_or_version = Git::Tag.new value
      when "branch" then rev_or_version = Git::Head.new value
      end
    end
    if path
      {path, rev_or_version}
    else
      raise "Can't convert dependency, no path"
    end
  end
end
