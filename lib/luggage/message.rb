module Luggage
  class Message
    class MessageNotFoundError < ArgumentError; end
    class DuplicateMessageError < StandardError; end

    attr_accessor :flags
    attr_reader :connection, :mailbox, :template, :date, :message_id

    # Creates a local Message instance
    #
    # `connection` should be an authenticated Imap connection
    # `mailbox` should be either a Mailbox or a string describing a remote mailbox
    # `args` will be passed to Message::new.  Keys used by Message::new will be set, any
    #   other keys will be delegated to Mail::Message.
    #
    # Example Usage:
    # Message.new_local(c, 'INBOX', :template => 'base.eml', :date => 4.days.ago)
    # Message.new_local(c, m, :subject => "VIAGRA ROCKS!", :body => "<insert phishing here>", :cc => "yourmom@gmail.com")
    #
    def self.new_local(connection, mailbox, args = {}, &block)
      message = new(connection, mailbox, args)
      message.instance_eval do
        @mail = @template ? Mail.read(@template) : Mail.new
        args.each do |key, value|
          mail[key] = value if mail.respond_to?(key)
        end

        if mail[:message_id] && !args.has_key?(:message_id)
          @message_id = mail.message_id
        else
          mail[:message_id] = message_id
        end
      end

      message.instance_eval &block if block_given?
      message
    end

    # Creates a Message instance
    #
    # `connection` should be an authenticated Imap connection
    # `mailbox` should be either a Mailbox or a string describing a remote mailbox
    # `args[:date]` when this message is appended to the remote server, this is the date which will be used
    # `args[:template]` use this file as the initial raw email content.
    # `args[:message_id]` use this as for the Message-ID header.  This header is used to identify messages across requests
    #
    def initialize(connection, mailbox, args = {}, &block)
      @connection = connection
      @mailbox = mailbox.kind_of?(Mailbox) ? mailbox : Mailbox.new(connection, mailbox)
      @flags = args.has_key?(:flags) ? Array(args[:flags]) : []
      @date = args[:date] || Time.now
      @template = args[:template]
      @message_id = args[:message_id] || "<#{UUIDTools::UUID.random_create}@test.oib.com>"

      instance_eval &block if block_given?
    end

    # Formatted to save to file
    #
    # Mail::Message.new( message.to_s ).raw_source = message.to_s
    #
    def to_s
      mail.encoded
    end

    # Fetch this message from the server and update all its attributes
    #
    def reload
      fields = fetch_fields
      @mail = Mail.new(fields["BODY[]"])
      @flags = fields["FLAGS"]
      @date = Time.parse(fields["INTERNALDATE"])
      self
    end

    # Append this message to the remote mailbox
    #
    def save!
      mailbox.select!
      connection.append(mailbox.name, raw_message, flags, date)
    end

    # Uses IMAP's COPY command to copy the message into the named mailbox
    #
    def copy_to!(mailbox_name)
      mailbox.select!
      connection.uid_copy([uid], Luggage::Mailbox.convert_mailbox_name(mailbox_name))
    end

    # Add the 'Deleted' flag to this message on the remote server
    #
    def delete!
      mailbox.select!
      connection.uid_store([uid], "+FLAGS", [:Deleted])
      @mail = nil
    end

    # Returns true if a message with the same message_id exists in the remote mailbox
    #
    def exists?
      mailbox.select!
      connection.uid_search("HEADER.PEEK Message-ID #{message_id}")
    end

    # Proxy all other methods to this instance's Mail::Message
    #
    def method_missing(meth, *args, &block)
       if mail.respond_to?(meth)
         mail.send(meth, *args, &block)
       else
         super
       end
    end

    def inspect
      "#<Luggage::Message server: \"#{host}\", mailbox: \"#{mailbox.name}\", message_id: \"#{message_id}\">"
    end

    def host
      connection.instance_variable_get(:@host)
    end

    private

    # Formatted to upload to IMAP server
    #
    def raw_message
      mail.to_s
    end

    def mail
      reload if @mail.nil?
      @mail
    end

    def uid
      return @uid if instance_variable_defined?(:@uid)

      mailbox.select!
      @uid = fetch_uid
    end

    def fetch_uid
      response = connection.uid_search("HEADER Message-ID #{message_id}")
      raise MessageNotFoundError if response.empty?
      raise DuplicateMessageError if response.length > 1
      response.first
    end

    def fetch_fields
      response = connection.uid_fetch([uid], ["FLAGS", "INTERNALDATE", "BODY.PEEK[]"])
      raise MessageNotFoundError if response.empty?
      raise DuplicateMessageError if response.length > 1
      response.first[:attr]
    end
  end
end

