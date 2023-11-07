# frozen_string_literal: true

class EventHub
  module Adapters
    class Aws
      class Message < EventHub::Message
        def initialize(adapter, message)
          @adapter = adapter
          @message = message
        end

        def attributes
          @attributes ||= parsed_body['MessageAttributes'].transform_values { |v| v['Value'] }
        end

        def body
          parsed_body['Message']
        end

        def event
          attributes['event']
        end

        def version
          attributes['version']
        end

        def ack
          # Delete the message from the queue.
          @adapter.delete_message(@message.receipt_handle)
        end

        def reject
          ack if @adapter.config[:delete_message_on_failure]
          # other wise it will be returned to the main queue and then after the maxReceiveCount it will be sent to
          # the DeadLetter queue
        end

        private

        # {
        #   "Type" : "Notification",
        #   "MessageId" : "025727dd-bb27-5c53-8a79-7b38f0cfe19a",
        #   "SequenceNumber" : "10000000000000020000",
        #   "TopicArn" : "arn:aws:sns:us-west-2:744522205193:event-hub.fifo",
        #   "Subject" : "subject",
        #   "Message" : "body",
        #   "Timestamp" : "2023-05-22T10:53:28.806Z",
        #   "UnsubscribeURL" : "https://sns.us-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-west-2:744522205193:event-hub.fifo:c8e1a595-4b0d-44b4-8087-094e7b0de09a",
        #   "MessageAttributes" : {
        #     "str_attr" : {"Type":"String","Value":"string_attr_val"}
        #   }
        # }
        def parsed_body
          @parsed_body ||= JSON.parse(@message.body)
        end
      end
    end
  end
end
