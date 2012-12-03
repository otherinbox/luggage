# Luggage

* [Homepage](https://github.com/otherinbox/luggage#readme)
* [Issues](https://github.com/otherinbox/luggage/issues)

DSL for interacting with Imap accounts

## Creating a factory

Factories provide the top-level interface for interacting with IMAP servers.
All factories require an authenticated `Net::IMAP` instance, however there
are multiple ways to get there:

### Using an existing Connection

If you have an instance of `Net::IMAP` you can pass it to the constructor as
`:connection` and the factory will use it.

``` ruby
f = Luggage.new(:connection => connection)
```

Keep in mind that the connection needs to be authenticated

### Using an authentication string

`Net::IMAP` natively supports `LOGIN` and `CRAM-MD5` authentication schemes,
if you want to use either of these you can pass in `:server` and `:authenticate`, 
the contents of `:authenticate` will be passed to `Net::IMAP#authenticate`.  

``` ruby
f = Luggage.new(:server => 'imap.aol.com', :authenticate => 'LOGIN user password')
f = Luggage.new(:server => ['imap.aol.com' 993, true], :authenticate => 'LOGIN user password')
```

Notice that the value of `:server` will be passed to `Net::IMAP#new`, so the full
syntax of the initializer is available.  See the Ruby docs for more details on
auth and intialization

### Using XOauth

Google has implemented XOauth for their IMAP connections.  To use this pass in
`:server` as before and a token as `:xoauth`

``` ruby
f = Luggage.new(:server => ['imap.gmail.com', 993, true], :xoauth => token)
```

See the documentation for you service provider for details on generating that token.


## Working with mailboxes

`Luggage#mailboxes` provides an interface to the different mailboxes on your
remote server.  To access existing mailboxes you can use a couple syntaxes:

``` ruby
Luggage.new(:connection => c) do
  mailboxes["SPAM"]   # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "SPAM">
  mailboxes("SPAM")   # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "SPAM">
  mailboxes[:inbox]   # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "INBOX">
  mailboxes[:g_all]   # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "[Gmail]/All Mail">
  mailboxes[0]        # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "INBOX">
  mailboxes(0)        # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "INBOX">
  mailboxes.first     # =>  #<Luggage::Mailbox server: "imap.gmail.com", name: "INBOX">
  mailboxes           # => [<Luggage::Mailbox server: "imap.gmail.com", name: "SPAM">...]
  mailboxes[0..10]    # => [<Luggage::Mailbox server: "imap.gmail.com", name: "INBOX">...]
end
```

In most cases you can use method call and array/hash index syntax interchangeably.
Mailboxes come with a couple useful helper methods:

``` ruby
Luggage.new(:connection => c) do
  mailboxes["New mailbox"].save!        # Creates the remote mailbox
  mailboxes["Old and busted"].delete!   # Deletes the remote mailbox
  mailboxes["Cheshire"].exists?         # Tells you if it exists remotely
  mailboxes["INBOX"].expunge!           # Permanently deletes any messages marked for deletion
end
```

## Querying messages

You can access the messages in a given mailbox through a couple helpers

``` ruby
Luggage.new(:connection => c) do
  mailboxes "INBOX" do
    all                           # Returns an array of all the messages in the mailbox
    first                         # Returns the first message (sorted by oldest first)
    where("SINCE", 5.days.ago)    # Executes Net::IMAP#search - see Ruby docs for mor info on search params
    where(:subject => "FI!")      # Shortcut for 'SUBJECT'
  end
end
```

Querying works somewhat like ActiveRecord scopes, in that you can chain calls to `where` 
to build up a compound query, which is only executed once you attempt to inspect the results.
Keep in mind that compound queries are generated by appending each key/value pair into
big string and sending it to the IMAP server - this isn't SQL

Messages are retrieved somewhat lazily.  The `Message-ID` and `uid` fields are always fetched, 
but the full body isn't fetched until you try to access a field like `subject` or `body`.
You can inspect retrieved messages using the same syntax as the [Mail](https://github.com/mikel/mail)
gem, for instance:

``` ruby
Luggage.new(:connection => c) do
  mailboxes "INBOX" do
    first.subject                 # The email subject
    first.to                      # TO: field
    first.headers['Return-Path']  # Random headers
    first.body                    # Decoded body
    first.multipart?              # Is this a multi-part email?

    first.flags                   # The flags set on the remote message
  end
end
```

Messages are uniquely identified by their `Message-ID` header, so if you want to access a
remote email you can fetch its data by creating a new messge instance and passing in the
message id:

``` ruby
Luggage.new(:connection => c) do
  message(:message_id => message_id).reload.flags
end
```

See the next section for more details on that `Luggage#message` method...

## Working with messages

`Luggage#message` and `Mailbox#message` provide interfaces for creating messages.  

* If you pass in a `:template` argument, the message will be created using the contents
of the file at that path.  
* If you pass an array as `:flags`, the passed flags will be set for the message when 
it's uploaded to the remote server.
* A date can be passed as `:date` and will be used as the recieved-at date when the message
is uploaded.  
* Any other arguments will be interpreted as properties to be set on the new message.  
These will be set after the template is read (if provided), allowing
you to tweak the templates if needed. 

If using the `Luggage` version, a mailbox must be specified as the first argument.

``` ruby
Luggage.new(:connection => c) do
  message("INBOX", :template => 'path/to/email.eml').save!
  
  mailboxes "INBOX" do
    message(:template => 'path/to/email.eml').save!
  
    message(:template => 'path/to/email.eml', :subject => "Custom subject").save!
    message do
      subject "Howdy"
      body "Partner"
      from "me@gmail.com"
      to "you@gmail.com"
      headers "DKIM-Signature" => "FAIL"
    end.save!
  end
end
```

_Don't forget to save_.  Cause otherwise it won't get uploaded.

You can also work with existing messages on the server, either by querying for
them or by instantiating them directly by their message id

``` ruby
Luggage.new(:connection => c) do
  mailboxes :g_all do
    message(:message_id => "<foo@example.com>").exists?     # Does a message with this Message-ID exist in this mailbox?
    message(:message_id => "<foo@example.com>").reload      # Re-download the content and flags of this message
    first.delete!                                           # Delete this message (add the 'Deleted' flag)
  end
end
```

## If you don't like playing with blocks

The examples so far have used DSL/block style syntax.  If you'd prefer to assign to
variables and use the methods directly that's fine too:

``` ruby
f = Luggage.new(:connection => c)
mb = f.maiboxes["INBOX"]
m = mb.message(:template => "path/to/foo.eml")
m.save!

Luggage.new(:connection => c).mailboxes["INBOX"].message(:template => path).save!
```

Enjoy!
