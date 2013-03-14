module Luggage
  class Factory
    attr_reader :connection

    # Factory
    #
    # Factories require an instance of Net::IMAP. Serveral methods are supported:
    #
    # Factory.new(:connection => connection)
    # In this case, `connection` should be an authorized Net::IMAP instance.
    #
    # Factory.new(:server => "imap.gmail.com", :xoauth => [token, string])
    # In this case we'll build a Net::IMAP instance and attempt to send a raw
    # XOAUTH authentication request using the supplied token.
    #
    # Factory.new(:server => 'imap.example.com', :login => [username, password])
    # In this case, we'll build a Net::IMAP instance and use the `#login` method
    # to authenticate. This isn't the same as using 'LOGIN' as the auth method
    # in the next example.
    #
    # Factory.new(:server => "imap.example.com", :authentication => [some_auth_method, appropriate, arguments])
    # In this case, we'll build a Net::IMAP instance and attempt to authenticate
    # with the value of `:authentication` by calling `Net::IMAP#authenticate`.
    def initialize(args = {}, &block)
      if args.has_key?(:connection)
        @connection = args[:connection]

      elsif args.has_key?(:server) && args.has_key?(:xoauth)
        @connection = Net::IMAP.new(*Array(args[:server]))
        @connection.authenticate('XOAUTH', *Array(args[:xoauth]))

      elsif args.has_key?(:server) && args.has_key?(:login)
        @connection = Net::IMAP.new(*Array(args[:server]))
        @connection.login(*Array(args[:login]))

      elsif args.has_key?(:server) && args.has_key?(:authenticate)
        @connection = Net::IMAP.new(*Array(args[:server]))
        @connection.authenticate(*Array(args[:authenticate]))

      else
        raise ArgumentError, 'Imap Connection required.'
      end

      instance_eval &block if block_given?
    end

    # Factory#message
    #
    # Constructs an Message
    #
    # `mailbox` can be either a string describing the Imap mailbox the message belongs to
    # or an instance of Mailbox.
    #
    # `args` will be passed to ImapFactorY::Message#new_local - see that method for details
    #
    def message(mailbox, args = {}, &block)
      Message.new_local(connection, mailbox, args, &block)
    end

    def mailboxes(*args)
      array = MailboxArray.new(connection)
      args.empty? ? array : array[*args]
    end

    def inspect
      "#<Luggage::Factory server: \"#{host}\">"
    end

    def host
      connection.instance_variable_get(:@host)
    end
  end
end
