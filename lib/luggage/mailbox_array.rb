module Luggage
  class MailboxArray
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def [](*args, &block)
      case args.first
      when String
        mailbox(args.first, &block)
      when :inbox, :spam, :sent, :trash
        mailbox(args.first.to_s.upcase, &block)
      when :g_all
        mailbox("[Gmail]/All Mail", &block)
      when :g_sent
        mailbox("[Gmail]/Sent", &block)
      when :g_trash
        mailbox("[Gmail]/Trash", &block)
      when Symbol
        mailbox(args.first, &block)
      when nil
        mailboxes
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
