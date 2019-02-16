require 'aws-sdk'

def sqs
  Aws::SQS::Client.new
end
