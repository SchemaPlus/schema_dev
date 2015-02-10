As usual:

```ruby
gem "%GEM_NAME%"                # in a Gemfile
gem.add_dependency "%GEM_NAME%" # in a .gemspec
```

To use with a rails app, also include

```ruby
gem "schema_monkey_rails"
```

which creates a Railtie to that will insert %GEM_MODULE% appropriately into the rails stack. To use with Padrino, see [schema_monkey_padrino](https://github.com/SchemaPlus/schema_monkey_padrino).
