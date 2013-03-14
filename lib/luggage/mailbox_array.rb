module Luggage
  class MailboxArray
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def [](*args, &block)
      mailbox_name = Luggage::Mailbox.convert_mailbox_name(args.first)

      if mailbox_name
        mailbox(mailbox_name, &block)
      else
        super
      end
    end

    def method_missing(meth, *args, &block)
      mailboxes.send(meth, *args, &block)
    end

    def inspect
      mailboxes.inspect
    end

    def host
      connection.instance_variable_get(:@host)
    end

    private

    # Cosntructs a Mailbox
    #
    # `name` should be a string describing the Imap mailbox's name
    #
    def mailbox(name, &block)
      Mailbox.new(connection, name, &block)
    end

    def mailboxes
      connection.list("", "*").map do |result|
        Mailbox.new(connection, result.name)
      end
    end
  end
end
