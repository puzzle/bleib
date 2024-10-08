# Bleib

## About

With bleib, your Rails application gains two new rake tasks:

* `bleib:wait_for_database` - waits until the database is running and the configured user can access it
* `bleib:wait_for_migrations` - performs `bleib:wait_for_database`, then waits until all migrations are up

Bleib knows about the [Apartment gem](https://github.com/influitive/apartment) - if your project
includes it, it will also check migrations on tenants. Likewise, it knows about the
[Wagons gem](https://github.com/puzzle/wagons) and checks for migrations in all known wagons.

This was built to be used in kubernetes/OpenShift deployments without a zero downtime approach.

It allows you to `kubectl apply` your multi-Rails-pod configuration and delegate migrations to either
a `Job` or one of the `Pod`s.
Using bleib `initContainer`s, dependent Rails `Pod`s (say job workers or multiple replicas) can wait
for migrations or DB redeployments to finish.

## How to

* Add the gem to your application: `gem 'bleib'`
* Build your application image.
* Add an `initContainer` that's based on your application image to your application `Pod`.
* Set the command of the `initContainer` to `rake bleib:wait_for_migrations`.
* Add some way to migrate the database so that the waiting actually pays off at some point.
* The migrations can be run after `rake bleib:wait_for_database` sees a connection.

### Configuration

Bleib's behaviour is configured via the environment:

| Environment variable            | Default value       | Description                                                                                                              |
|---------------------------------|---------------------|--------------------------------------------------------------------------------------------------------------------------|
| BLEIB_CHECK_DATABASE_INTERVAL   | 5                   | Seconds to wait between database readiness checks                                                                        |
| BLEIB_CHECK_MIGRATIONS_INTERVAL | 5                   | Seconds to wait between migration readiness checks                                                                       |
| BLEIB_DATABASE_YML_PATH         | config/database.yml | Path to database.yml. Bleib needs this to perform database readiness checks without booting the whole rails environment. |
| BLEIB_LOG_LEVEL                 | info                | Set this to `debug` to investigate why bleib is hanging.                                                                 |
| BLEIB_DEFAULT_TENANT            | public              | Name of well-known always existing Tenant. This depends on the strategy you use with Apartment and your RDBMS. |

## Caveats

* Handles the `postgresql`, `postgis` and `mysql2` database adapters.
  It's simple to add further adapters, see `Bleib::Database#database_down_exception?` and `Bleib::Configuration#check!`

## Testing

Done by hand so far.

If I had a magic wand, I'd do integration tests of `Bleib::Database` and `Bleib::Migrations` against
a database container in various states (up, down, preloaded with dumps of different migration states).

## ToDo (patches welcome)

- [ ] add a basic rspec skeleton
- [ ] add (mocked) specs for `Bleib::Migrations`
- [ ] add (mocked) specs for `Bleib::Database`
- [ ] add integration test for `Bleib::Database`
- [ ] add integration test for `Bleib::Migrations`
- [ ] add specs for `Bleib::Configuration`
