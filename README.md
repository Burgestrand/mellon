# Mellon

> Speak, Friend, and enter.

Mellon is three things:

- A simple library for reading and writing notes in Mac OSX keychains.
- A tiny CLI for reading and writing notes in Mac OSX keychains.
- An adapter for [econfig](https://github.com/elabs/econfig).

I built Mellon because I wanted Yet Another Way of Managing Rails Application Secrets™.

Mellon is sponsored by [Elabs][].

[![elabs logo][]](http://elabs.se/)

## Using with Econfig (recommended)

Add to your Gemfile:

```ruby
gem "mellon", require: "mellon/econfig"
```

And create an initializer for Econfig:

```ruby
if Rails.env.development?
  keychain_name = "projects"
  Econfig.instance.backends << Econfig::Mellon.new(keychain_name)
end
```

## Using through CLI

First, the set-up:

1. Configure an OSX keychain, shared between your fellow developers through e.g. iCloud.

Now, when you create a new project, and once you need secret credentials, you:

1. `mellon edit -k shared_keychain`.

[Elabs]: http://elabs.se/
[elabs logo]: ./elabs-logo.png?raw=true
