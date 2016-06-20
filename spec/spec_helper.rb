if ENV.has_key? "CODECLIMATE_REPO_TOKEN"
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require "rubygems"

$: << 'lib'

require "fresh-mc"

NS=32
#NS=256
#NS=512
#NS=1024
