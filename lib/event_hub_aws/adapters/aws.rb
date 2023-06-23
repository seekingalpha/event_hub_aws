# frozen_string_literal: true

require 'aws-sdk-sns'
require 'aws-sdk-sqs'

class EventHub
  module Adapters
    class Aws
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def subscribe(&block)
        loop do
          receive_message_result = sqs.receive_message(
            queue_url: @config[:queue_url],
            message_attribute_names: ['All'], # Receive all custom attributes.
            max_number_of_messages: 10, # Receive at most one message.
            wait_time_seconds: 15 # Do not wait to check for the message.
          )

          # Display information about the message.
          # Display the message's body and each custom attribute value.
          receive_message_result.messages.each do |aws_msg|
            message = Message.new(self, aws_msg)
            block.call(message)
          end
        end
      end

      def publish(event)
        topic.publish({
                        message: event.body,
                        message_attributes: {
                          event: { data_type: 'String', string_value: event.class.event },
                          version: { data_type: 'String', string_value: event.class.version },
                        },
                        message_group_id: 'message_group_id',
                        message_deduplication_id: SecureRandom.uuid
                      })
      end

      def setup_bindings
        events = @config[:subscribe].keys
        events = ['__nothing__'] if events.empty? # AWS doesn't allow blank filters
        policy = { event: events }.to_json
        subscription = topic.subscriptions.find { |s| s.attributes['Endpoint'] == @config[:queue_arn] }
        if subscription
          subscription.set_attributes({
                                        attribute_name: 'FilterPolicy',
                                        attribute_value: policy
                                      })
        else
          topic.subscribe({
                            protocol: 'sqs',
                            attributes: { 'FilterPolicy' => policy },
                            endpoint: @config[:queue_arn]
                          })
        end
      end

      def delete_message(receipt_handle)
        sqs.delete_message(
          queue_url: @config[:queue_url],
          receipt_handle: receipt_handle
        )
      end

      def topic
        @topic ||= sns.topic(@config[:exchange_arn])
      end

      def sns
        @sns ||= ::Aws::SNS::Resource.new(@config[:credentials] || {})
      end

      def sqs
        @sqs ||= ::Aws::SQS::Client.new(@config[:credentials] || {})
      end
    end
  end
end
