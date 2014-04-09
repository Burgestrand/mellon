# Mellon

> Speak, Friend, and enter.

Mellon is four things:

- A simple library for reading and writing notes in Mac OSX keychains. (see [Mellon::Keychain][])
- A simple library for using Mac OSX keychain notes as hash storage. (see [Mellon::Store][])
- A tiny CLI interface for [Mellon::Keychain][]. (see [Command-line interface](#command-line-interface))

I built Mellon because I wanted Yet Another Way of Managing Application Secrets™. Frankly, I am fed up
with passing around some secret file not included in our source code repository that runs out of sync
every time we add or change values during development.

Mellon, together with Econfig, solves this problem.

Mellon is sponsored by [Elabs][].

[![elabs logo][]][Elabs]

## Usage

Mellon is intended for usage during development only. The recommended workflow is:

1. Create an OSX keychain using Keychain Access, name it something hip and clever, like `thanks-a-latte`.
2. Share your keychain with your colleagues, through iCloud sync, Dropbox or similar.
3. Hook up Mellon with your application according to instructions below.

### Using with Rails and Econfig (recommended)

See instructions over at [econfig-keychain](https://github.com/elabs/econfig-keychain).

# Documentation

An API reference can be found at [rdoc.info/github/elabs/mellon](http://rdoc.info/github/elabs/mellon/master/frames).

## Mellon::Keychain

Mellon::Keychain allows you to read and write notes in OSX keychains.

```ruby
keychain = Mellon::Keychain.default
keychain["ruby note"] # => nil
keychain["ruby note"] = "Hello from Ruby!" # creates keychain note `ruby note`
keychain["ruby note"] # => "Hello from Ruby!"
keychain["ruby note"] = nil # deletes keychain note `ruby note`
```

More documentation can be found at the [API reference for Mellon::Keychain](http://rdoc.info/github/elabs/mellon/master/Mellon/Keychain).

## Mellon::Store

Mellon::Store is a layer above Mellon::Keychain, allowing you to use a single keychain note as hash storage. Notes are serialized as YAML by default.

```ruby
project_name = "ruby note"
store = Mellon::Store.new(project_name, keychain: Mellon::Keychain.default)
store["some key"] # => nil
store["some key"] = "Hello from Ruby!" # creates keychain note "ruby note", and puts value for "some key" in it
store["some key"] # => "Hello from Ruby!"

# Have a peek at the data, which is serialized as YAML
store.keychain[store.project_name] # => "---\nsome key: Hello from Ruby!\n"
```

More documentation can be found at the [API reference for Mellon::Store](http://rdoc.info/github/elabs/mellon/master/Mellon/Store).

## Command-line interface

When you install the Mellon gem you also get an executable called `mellon`. See `mellon -h` for usage information.

# License

[See MIT-LICENSE.txt](./MIT-LICENSE.txt).

[Elabs]: http://www.elabs.se/
[elabs logo]: ./elabs-logo.png?raw=true
[Mellon::Keychain]: #mellon-keychain
[Mellon::Store]: #mellon-store
