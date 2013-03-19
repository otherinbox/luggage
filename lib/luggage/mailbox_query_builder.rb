module Luggage
  class MailboxQueryBuilder
    include Enumerable

    attr_reader :connection, :mailbox, :query

    # Provides an ActiveRecord-style query interface to emails on the remote server
    #
    # `mailbox` should be a Mailbox instance describing the remote mailbox to be queried
    #
    def initialize(mailbox)
      raise ArgumentError, "Luggage::Mailbox required" unless mailbox.kind_of?(Mailbox)

      @mailbox = mailbox
      @connection = mailbox.connection
      @query = []
    end

    # Executes the query and yields to each returned result
    #
    def each(&block)
      messages.each(&block)
    end

    # Builds an Imap search query from the passed `args` hash.  Each key is treated as
    # a search key, each value is treated as a search value.  Key/value pairs are appended
    # to an array which will be passed to Net::IMAP#search.  For more details on search
    # syntax see Ruby std lib docs for Net::IMAP
    #
    def where(args = {})
      @message_ids = nil
      @messages = nil

      args.each do |key, value|
        case key.to_sym
        when :body, :subject, :to, :cc, :from
          @query += [key.to_s.upcase, value]
        else
          @query += [key, value]
        end
      end
      self
    end

    # Executes the query and returns a slice of the resulting array of messages
    #
    def [](*args)
      messages.[](*args)
    end

    def messages
      @messages ||= message_ids.map {|message_id| Message.new(connection, mailbox, :message_id => message_id)}
    end

    def inspect
      "#<Luggage::MailboxQueryBuilder server: \"#{host}\", mailbox: \"#{mailbox.name}\", query: #{query}>"
    end

    def host
      connection.instance_variable_get(:@host)
    end

    private

    def uids
      mailbox.select!
      connection.uid_search(@query.empty? ? "ALL" : @query)
    end

    def message_ids
      @message_ids ||= begin
        field = "BODY[HEADER.FIELDS (Message-ID)]"

        if uids.empty?
          []
        else
          connection.uid_fetch(uids, field).map do |resp|
            $1 if resp[:attr][field] =~ /(<\S*@\S*>)/
          end.compact
        end
      end
    end
  end
end
