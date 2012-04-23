require 't/core_ext/string'
require 't/rcfile'
require 't/requestable'
require 'thor'

module T
  class Delete < Thor
    include T::Requestable

    check_unknown_options!

    def initialize(*)
      super
      @rcfile = RCFile.instance
    end

    desc "block SCREEN_NAME [SCREEN_NAME...]", "Unblock users."
    def block(screen_name, *screen_names)
      screen_names.unshift(screen_name)
      screen_names.threaded_each do |screen_name|
        screen_name.strip_at
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.unblock(screen_name, :include_entities => false)
        end
      end
      say "@#{@rcfile.default_profile[0]} unblocked @#{screen_names.join(' ')}."
      say
      say "Run `#{File.basename($0)} block #{screen_names.join(' ')}` to block."
    end

    desc "dm", "Delete the last Direct Message sent."
    def dm
      direct_message = client.direct_messages_sent(:count => 1, :include_entities => false).first
      if direct_message
        unless options['force']
          return unless yes? "Are you sure you want to permanently delete the direct message to @#{direct_message.recipient.screen_name}: \"#{direct_message.text}\"? [y/N]"
        end
        direct_message = client.direct_message_destroy(direct_message.id, :include_entities => false)
        say "@#{direct_message.sender.screen_name} deleted the direct message sent to @#{direct_message.recipient.screen_name}: \"#{direct_message.text}\""
      else
        raise Thor::Error, "Direct Message not found"
      end
    end
    map %w(m) => :dm

    desc "favorite STATUS_ID [STATUS_ID...]", "Delete favorites."
    def favorite(status_id, *status_ids)
      status_ids.unshift(status_id)
      status_ids.each do |status_id|
        unless options['force']
          status = client.status(status_id, :include_entities => false, :include_my_retweet => false, :trim_user => true)
          return unless yes? "Are you sure you want to delete the favorite of @#{status.user.screen_name}'s status: \"#{status.text}\"? [y/N]"
        end
        status = client.unfavorite(status_id, :include_entities => false)
        say "@#{@rcfile.default_profile[0]} unfavorited @#{status.user.screen_name}'s status: \"#{status.text}\""
      end
    end
    map %w(post tweet update) => :status

    desc "list LIST_NAME", "Delete a list."
    def list(list_name)
      unless options['force']
        return unless yes? "Are you sure you want to permanently delete the list \"#{list_name}\"? [y/N]"
      end
      status = client.list_destroy(list_name)
      say "@#{@rcfile.default_profile[0]} deleted the list \"#{list_name}\"."
    end

    desc "status STATUS_ID [STATUS_ID...]", "Delete Tweets."
    def status(status_id, *status_ids)
      status_ids.unshift(status_id)
      status_ids.each do |status_id|
        unless options['force']
          status = client.status(status_id, :include_entities => false, :include_my_retweet => false, :trim_user => true)
          return unless yes? "Are you sure you want to permanently delete @#{status.user.screen_name}'s status: \"#{status.text}\"? [y/N]"
        end
        status = client.status_destroy(status_id, :include_entities => false, :trim_user => true)
        say "@#{@rcfile.default_profile[0]} deleted the status: \"#{status.text}\""
      end
    end
    map %w(post tweet update) => :status

  end
end
