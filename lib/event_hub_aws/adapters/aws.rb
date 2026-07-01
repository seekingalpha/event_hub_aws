# frozen_string_literal: true

require 'aws-sdk-sns'
require 'aws-sdk-sqs'

class EventHub
  module Adapters
    class Aws
      DEFAULT_CONFIG = {
        delete_message_on_failure: false,
        message_attribute_names: ['All'],
        max_number_of_messages: 10,
        wait_time_seconds: 15,
        visibility_timeout: 30
      }.freeze

      attr_reader :config

      def initialize(config)
        @config = config.merge(DEFAULT_CONFIG) { |_k, config_value, _default_value| config_value }
      end

      def subscribe(&block)
        loop do
          receive_message_result = sqs.receive_message(
            queue_url: @config[:queue_url],
            message_attribute_names: @config[:message_attribute_names],
            max_number_of_messages: @config[:max_number_of_messages],
            wait_time_seconds: @config[:wait_time_seconds],
            visibility_timeout: @config[:visibility_timeout]
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
        message = {
          message: event.body,
          message_attributes: {
            event: { data_type: 'String', string_value: event.class.event },
            version: { data_type: 'String', string_value: event.class.version },
          },
        }
        if fifo_exchange?
          message.merge!(message_group_id: 'message_group_id', message_deduplication_id: SecureRandom.uuid)
        end
        topic.publish(message)
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

      def change_message_visibility(receipt_handle, visibility_timeout = 0)
        sqs.change_message_visibility(
          queue_url: @config[:queue_url],
          receipt_handle: receipt_handle,
          visibility_timeout: visibility_timeout
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

      def fifo_exchange?
        return @fifo_exchange if defined?(@fifo_exchange)

        @fifo_exchange = @config[:exchange_arn].end_with?('.fifo')
      end
    end
  end
end
