# Bleib

# About

With bleib, your Rails application gains two new rake tasks:

* `wait_for_database` - waits until the database is running and the configured user can access it
* `wait_for_migrations` - performs `wait_for_database`, then waits until all migrations are up

Bleib knows about the [Apartment gem](https://github.com/influitive/apartment) - if your project 
includes it, it will also check migrations on tenants.

This was built to be used in kubernetes/OpenShift deployments without a zero downtime approach.

It allows you to `kubectl apply` your multi-Rails-pod configuration and delegate migrations to either 
a `Job` or one of the `Pod`s. 
Using bleib `initContainer`s, dependent Rails `Pod`s (say job workers or multiple replicas) can wait 
for migrations or DB redeployments to finish.

# How to

* Add the gem to your application: `gem 'bleib', '0.0.9'`
* Build your application image.
* Add an `initContainer` that's based on your application image to your application `Pod`.
* Set the command of the `initContainer` to `rake wait_for_migrations`.

## Configuration

Bleib's behaviour is configured via the environment:

| Environment variable            | Default value       | Description                                                                                                              |
|---------------------------------|---------------------|--------------------------------------------------------------------------------------------------------------------------|
| BLEIB_CHECK_DATABASE_INTERVAL   | 5                   | Seconds to wait between database readiness checks                                                                        |
| BLEIB_CHECK_MIGRATIONS_INTERVAL | 5                   | Seconds to wait between migration readiness checks                                                                       |
| BLEIB_DATABASE_YML_PATH         | config/database.yml | Path to database.yml. Bleib needs this to perform database readiness checks without booting the whole rails environment. |
| BLEIB_LOG_LEVEL                 | info                | Set this to `debug` to investigate why bleib is hanging.                                                                 |
| BLEIB_DEFAULT_TENANT            | public              | Name of well-known always existing Tenant. This depends on the strategy you use with Apartment and your RDBMS. |

# Caveats

* Handles the `postresql`, `postgis` and `mysql2` database adapters.
  It's simple to add further adapters, see `Bleib::Database#database_down_exception?` and `Bleib::Configuration#check!`

# Testing

Done by hand so far.

If I had a magic wand, I'd do integration tests of `Bleib::Database` and `Bleib::Migrations` against
a database container in various states (up, down, preloaded with dumps of different migration states).
