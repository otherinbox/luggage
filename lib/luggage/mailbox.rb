module Luggage
  class Mailbox
    include Enumerable

    attr_reader :connection, :name

    # This provides an interface to a remote Imap mailbox
    #
    # `connection` should be an authenticated Net::IMAP
    #
    # `name` is the name of the remote mailbox
    #
    def initialize(connection, name, &block)
      @connection = connection
      @name = name

      instance_eval &block if block_given?
    end

    # Constructs an Message whose mailbox will be set to this instance
    #
    # `args` will be passed to ImapFactorY::Message#new_local - see that method for details
    #
    def message(args = {}, &block)
      Message.new_local(connection, self, args, &block)
    end

    # Returns true if this mailbox exists on the remote server, false otherwise
    #
    def exists?
      return @exists if instance_variable_defined?(:@exists)

      @exists = !connection.list("", name).empty?
    end

    # Deletes this mailbox on the remote server
    #
    def delete!
      connection.delete(name)
      @exists = false
    end

    # Selects this mailbox for future Imap commands.
    #
    def select!
       connection.select(name)
    end

    # Creates the mailbox on the remote server if it doesn't exist already
    #
    def save!
      unless exists?
        connection.create(name)
      end
    end

    # Removes 'deleted' messages on the remote server.  Message#delete! marks
    # messages with the 'Deleted' flag, but leaves them on the server.  This removes
    # them entirely
    #
    def expunge!
      select!
      connection.expunge()
    end

    # Returns an array of Message instances describing all emails in the remote mailbox
    #
    def all
      MailboxQueryBuilder.new(self)
    end

    # Returns a Message instance describing the first email on the remote mailbox
    #
    def first
      all.first
    end

    # Iterates over Mailbox#each
    #
    def each(&block)
      all.each(&block)
    end

    # Filters emails on the remote server
    #
    # Returns a MailboxQueryBuilder - see MailboxQueryBuilder#where for usage details
    #
    def where(*args)
      all.where(*args)
    end

    def inspect
      "#<Luggage::Mailbox server: \"#{host}\", name: \"#{name}\">"
    end

    def host
      connection.instance_variable_get(:@host)
    end
  end
end
