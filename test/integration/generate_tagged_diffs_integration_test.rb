require File.expand_path(File.join(File.dirname(__FILE__), "../integration_test_helper.rb"))
require "resque_jobs/generate_tagged_diffs"
require "lib/syntax_highlighter"

class GenerateTaggedDiffsIntegrationTest < Scope::TestCase
  include IntegrationTestHelper

  context "generating diffs" do
    setup do
      stub(RedisManager.get_redis_instance).get { nil }
      @written_keys = []
      stub(RedisManager.get_redis_instance).set { |key, value| @written_keys.push(key) }
    end

    should "generate diffs for the given commit" do
      commit = test_repo.head.commit
      GenerateTaggedDiffs.perform("test_git_repo", commit.sha)
      # NOTE(philc): This assertion isn't particularly strong. It would be nice to be more specific,
      # but this is an effective sanity check to ensure that the highlighting results made it into redis.
      redis_key = SyntaxHighlighter.redis_cache_key("test_git_repo", commit.diffs.first.a_blob)
      assert @written_keys.include?(redis_key)
    end
  end
end